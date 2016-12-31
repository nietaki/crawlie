defmodule Crawlie.Stage.UrlManager do
  alias Experimental.GenStage
  alias Crawlie.Page
  alias Heap
  alias __MODULE__, as: This

  use GenStage

  require Logger

  #===========================================================================
  # State
  #===========================================================================

  defmodule State do
    @type t :: %State{
      # incoming
      initial: Enum.t, # pages provided by the user
      discovered: Heap.t, # pages discovered while crawling

      # current
      pending_demand: integer,
      visited: MapSet.t,
      in_flight: MapSet.t, # urls currently being processed by the rest of the flow

      #others
      options: Keyword.t,
    }

    @enforce_keys [:initial, :discovered, :options]
    defstruct [
      :initial,
      :discovered,
      :options,
      visited: MapSet.new,
      in_flight: MapSet.new,
      pending_demand: 0,
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

      if depth > max_depth do
        Logger.error "Trying to add a page #{inspect page.url} with 'depth' > max_depth: #{depth}"
        state
      else
        if retries <= max_retries do
          discovered = Heap.push(discovered, page)
          %State{state | discovered: discovered}
        else
          Logger.warn("After #{page.retries} retries, failed to fetch #{page.url}.")
          state
        end
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
        case {page, State.visited?(state, page.url)} do
          {%Page{retries: 0}, true} ->
            # if retries > 0, it doesn't matter if the page was visited before, we're just retrying
            _take_pages(state, count, acc)
          {page, _} ->
            state = state
              |> State.visit(page.url)
              |> State.started_processing(page.url)
            _take_pages(state, count - 1, [page | acc])
        end
      end
    end

    @spec visit(State.t, String.t) :: State.t
    @doc """
    Marks the url as "already visited" in the state
    """
    def visit(%State{visited: visited} = state, url) do
      visited = MapSet.put(visited, url)
      %State{state | visited: visited}
    end


    @spec visited?(State.t, String.t) :: boolean
    @doc """
    Checks if the url was already visited by the crawler
    """
    def visited?(%State{visited: visited}, url) do
      MapSet.member?(visited, url)
    end


    @spec started_processing(State.t, String.t) :: State.t
    def started_processing(%State{in_flight: in_flight} = state, url) when is_binary(url) do
      in_flight = MapSet.put(in_flight, url)
      %State{state | in_flight: in_flight}
    end


    @spec finished_processing(State.t, String.t):: State.t
    def finished_processing(%State{in_flight: in_flight} = state, url) when is_binary(url) do
      in_flight = MapSet.delete(in_flight, url)
      %State{state | in_flight: in_flight}
    end


    @spec finished_crawling?(State.t) :: boolean
    def finished_crawling?(%State{initial: initial, discovered: discovered, in_flight: in_flight}) do
      Enum.empty?(in_flight) and
        Heap.empty?(discovered) and
        Enum.empty?(initial)
    end
  end

  #===========================================================================
  # Manager - API Functions
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


  @spec add_children_pages(GenStage.stage, [Page.t]) :: :ok
  def add_children_pages(url_manager_stage, pages) do
    GenStage.cast(url_manager_stage, {:add_pages, pages})
  end


  @spec page_failed(GenStage.stage, Page.t) :: :ok
  def page_failed(url_manager_stage, failed_page) do
    GenStage.cast(url_manager_stage, {:page_failed, failed_page})
  end


  @spec page_succeeded(GenStage.stage, Page.t) :: :ok
  def page_succeeded(url_manager_stage, succeeded_page) do
    GenStage.cast(url_manager_stage, {:page_succeeded, succeeded_page})
  end

  #===========================================================================
  # GenStage callbacks
  #===========================================================================

  def init(%{pages: pages, crawlie_options: opts}) do
    {:producer, State.new(pages, opts)}
  end


  def handle_demand(demand, %State{pending_demand: pending_demand} = state) do
    %State{state | pending_demand: pending_demand + demand}
      |> do_handle_demand()
  end

  def handle_cast({:add_pages, pages}, %State{} = state) do
    State.add_pages(state, pages)
      |> do_handle_demand()
  end

  def handle_cast({:page_failed, %Page{} = page}, %State{} = state) do
    state
      |> State.finished_processing(page.url)
      |> State.add_pages([Page.retry(page)])
      |> do_handle_demand()
  end

  def handle_cast({:page_succeeded, %Page{} = page}, %State{} = state) do
    state
      |> State.finished_processing(page.url)
      |> do_handle_demand()
  end


  #===========================================================================
  # Helper functions
  #===========================================================================

  defp do_handle_demand(state) do
    demand = state.pending_demand
    {state, pages} = State.take_pages(state, demand)
    remaining_demand = demand - Enum.count(pages)
    state = %State{state | pending_demand: remaining_demand}

    if State.finished_crawling?(state) do
      Logger.debug("crawling finished")
      shutdown_gracefully(self())
    end

    {:noreply, pages, state}
  end


  defp shutdown_gracefully(pid), do: GenStage.async_notify(pid, {:producer, :done})

end
