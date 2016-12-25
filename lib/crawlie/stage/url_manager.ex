defmodule Crawlie.Stage.UrlManager do
  alias Experimental.GenStage
  alias Crawlie.Page
  alias Heap
  alias __MODULE__, as: This

  use GenStage

  require Logger

  defmodule State do
    @type t :: %State{
      # incoming
      initial: Enum.t, # pages provided by the user
      discovered: Heap.t, # pages discovered while crawling

      # current
      pending_demand: integer,
      visited: MapSet.t,

      #others
      shutdown_tref: term,
      options: Keyword.t,
    }

    @enforce_keys [:initial, :discovered, :options]
    defstruct [
      :initial,
      :discovered,
      :options,
      visited: MapSet.new,
      pending_demand: 0,
      shutdown_tref: nil
    ]

    @spec new(Enum.t, Keyword.t) :: State.t
    def new(initial_pages, options) do
      %State{
        initial: initial_pages,
        discovered: Heap.max(),
        options: options,
      }
    end

    @spec add_pages(State.t, [Page.t]) :: State.t

    def add_pages(state, pages) when is_list(pages) do
      Enum.reduce(pages, state, &add_page(&2, &1))
    end

    def add_page(%State{discovered: discovered} = state, %Page{depth: depth, retries: retries} = page) do
      max_depth = Keyword.get(state.options, :max_depth)
      max_retries = Keyword.get(state.options, :max_retries)

      case {depth <= max_depth, retries <= max_retries} do
        {true, true} ->
          discovered = Heap.push(discovered, page)
          %State{state | discovered: discovered}
        {_, false} ->
          Logger.warn("After #{page.retries} retries, failed to fetch #{page.url}.")
          state
        {_, _} ->
          state
      end
    end


    @spec take_pages(State.t, integer) :: {State.t, [Page.t]}
    def take_pages(%State{} = state, count) do
      _take_pages(state, count, [])
    end


    defp _take_pages(state, count, acc) when count <= 0, do: {state, acc}
    defp _take_pages(state, count, acc) do
      {state, page} = cond do
        !Heap.empty?(state.discovered) ->
          discovered = state.discovered
          page = Heap.root(discovered)
          {%State{state | discovered: Heap.pop(discovered)}, page}
        !Enum.empty?(state.initial) ->
          initial = state.initial
          [page] = Enum.take(initial, 1)
          {%State{state | initial: Enum.drop(initial, 1)}, page}
        true -> {state, nil}
      end

      if page == nil do
        {state, acc}
      else
        already_visited = MapSet.member?(state.visited, page.url)
        case {page, already_visited} do
          {%Page{retries: 0}, true} ->
            # if retries > 0, it doesn't matter if the page was visited before, we're just retrying
            _take_pages(state, count, acc)
          {page, _} ->
            visited = MapSet.put(state.visited, page.url)
            _take_pages(%State{state | visited: visited}, count - 1, [page | acc])
        end
      end
    end

  end

  #===========================================================================
  # API Functions
  #===========================================================================

  @spec start_link(Stream.t, Keyword.t) :: {:ok, GenStage.stage}

  def start_link(urls, crawlie_options) when is_list(crawlie_options) do
    pages = Stream.map(urls, &Page.new(&1))
    init_args = %{
      pages: pages,
      crawlie_options: crawlie_options,
    }
    GenStage.start_link(This, init_args)
  end


  def add_pages(url_manager_stage, pages) when is_list(pages) do
    GenStage.cast(url_manager_stage, {:add_pages, pages})
  end

  #===========================================================================
  # GenStage callbacks
  #===========================================================================

  def init(%{pages: pages, crawlie_options: opts}) do
    {:producer, State.new(pages, opts)}
  end


  def handle_demand(demand, %State{pending_demand: pending_demand} = state) do
    state = %State{state | pending_demand: pending_demand + demand}
    do_handle_demand(state)
  end

  def handle_cast({:add_pages, pages}, %State{} = state) do
    state = State.add_pages(state, pages)
    do_handle_demand(state)
  end


  #===========================================================================
  # Helper functions
  #===========================================================================

  def do_handle_demand(state) do
    demand = state.pending_demand
    {state, pages} = State.take_pages(state, demand)
    remaining_demand = demand - Enum.count(pages)
    state = %State{state | pending_demand: remaining_demand}

    state = if remaining_demand > 0 do
      shutdown_gracefully_after_timeout(state)
    else
      cancel_shutdown_timeout(state)
    end

    {:noreply, pages, state}
  end


  def shutdown_gracefully_after_timeout(state) do
    timeout = Keyword.get(state.options, :url_manager_timeout)
    state = cancel_shutdown_timeout(state)
    {:ok, tref} = :timer.apply_after(timeout, This, :shutdown_gracefully, [self()])
    %State{state | shutdown_tref: tref}
  end


  def shutdown_gracefully(pid), do: GenStage.async_notify(pid, {:producer, :done})


  def cancel_shutdown_timeout(%State{shutdown_tref: nil} = state), do: state
  def cancel_shutdown_timeout(%State{shutdown_tref: tref} = state) do
    {:ok, :cancel} = :timer.cancel(tref)
    %State{state | shutdown_tref: nil}
  end

end
