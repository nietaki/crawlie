defmodule Crawlie.Stage.UrlManager do
  alias Crawlie.Options
  alias Crawlie.Page
  alias Crawlie.PqueueWrapper, as: PriorityQueue
  alias __MODULE__, as: This

  use GenStage

  require Logger

  #===========================================================================
  # State
  #===========================================================================

  defmodule State do
    @type t :: %State{
      discovered: PriorityQueue.t, # pages discovered while crawling and the initial pages
      pending_demand: integer,
      visited: MapSet.t,
      in_flight: MapSet.t, # urls currently being processed by the rest of the flow

      options: Keyword.t,
    }

    @enforce_keys [:discovered, :options]
    defstruct [
      :discovered,
      :options,
      visited: MapSet.new,
      in_flight: MapSet.new,
      pending_demand: 0,
    ]

    @spec new(Enum.t, Keyword.t) :: State.t
    def new(initial_pages, options) do
      pqueue_module = Options.get_pqueue_module(options)
      state = %State{
        discovered: PriorityQueue.new(pqueue_module),
        options: options,
      }

      add_pages(state, initial_pages)
    end

    @spec add_pages(State.t, [Page.t]) :: State.t

    def add_pages(state, pages) do
      Enum.reduce(pages, state, &add_page(&2, &1))
    end

    def add_page(%State{discovered: discovered} = state, page) do
      max_depth = Keyword.get(state.options, :max_depth)
      max_retries = Keyword.get(state.options, :max_retries)

      cond do
        page.depth > max_depth ->
          Logger.error "Trying to add a page \"#{Page.url(page)}\" with 'depth' > max_depth: #{page.depth}"
          state
        page.retries > max_retries ->
          Logger.warn("After #{page.retries} retries, failed to fetch #{page.uri}.")
          state
        page.retries == 0 and State.visited?(state, page.uri) ->
          # not re-adding an already visited uri.
          state
        true ->
          # not doing the `visited` check because retries would classify as visited
          state = State.visit(state, page.uri)
          discovered = PriorityQueue.add_page(discovered, page)
          %State{state | discovered: discovered}
      end
    end


    @spec take_pages(State.t, integer) :: {State.t, [Page.t]}
    def take_pages(%State{} = state, count) do
      _take_pages(state, count, [])
    end


    defp _take_pages(state, count, acc) when count <= 0, do: {state, acc}
    defp _take_pages(state, count, acc) do
      {state, page} = cond do
        !PriorityQueue.empty?(state.discovered) ->
          {discovered, page} = PriorityQueue.take(state.discovered)
          {%State{state | discovered: discovered}, page}
        true -> {state, nil}
      end

      case page do
        nil ->
          {state, acc}
        %Page{uri: uri} ->
          state = State.started_processing(state, uri)
          _take_pages(state, count - 1, [page | acc])
      end
    end

    @spec visit(State.t, URI.t) :: State.t
    @doc """
    Marks the uri as "already visited" in the state
    """
    def visit(%State{visited: visited} = state, uri) do
      visited = MapSet.put(visited, uri)
      %State{state | visited: visited}
    end


    @spec visited?(State.t, URI.t) :: boolean
    @doc """
    Checks if the uri was already visited by the crawler
    """
    def visited?(%State{visited: visited}, uri) do
      MapSet.member?(visited, uri)
    end


    @spec started_processing(State.t, URI.t) :: State.t
    def started_processing(%State{in_flight: in_flight} = state, %URI{} = uri) do
      in_flight = MapSet.put(in_flight, uri)
      %State{state | in_flight: in_flight}
    end


    @spec finished_processing(State.t, String.t):: State.t
    def finished_processing(%State{in_flight: in_flight} = state, %URI{} = uri) do
      in_flight = MapSet.delete(in_flight, uri)
      %State{state | in_flight: in_flight}
    end


    @spec finished_crawling?(State.t) :: boolean
    def finished_crawling?(%State{discovered: discovered, in_flight: in_flight}) do
      Enum.empty?(in_flight) and
      PriorityQueue.empty?(discovered)
    end
  end

  #===========================================================================
  # Manager - API Functions
  #===========================================================================

  @spec start_link(Stream.t, Keyword.t) :: {:ok, GenStage.stage}

  def start_link(uris, crawlie_options) when is_list(crawlie_options) do
    pages = Stream.map(uris, &Page.new(&1))
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

  @spec page_skipped(GenStage.stage, Page.t) :: :ok
  def page_skipped(url_manager_stage, skipped_page) do
    GenStage.cast(url_manager_stage, {:page_skipped, skipped_page})
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
      |> State.finished_processing(page.uri)
      |> State.add_pages([Page.retry(page)])
      |> do_handle_demand()
  end

  def handle_cast({:page_skipped, %Page{} = page}, %State{} = state) do
    state
      |> State.finished_processing(page.uri)
      |> do_handle_demand()
  end

  def handle_cast({:page_succeeded, %Page{} = page}, %State{} = state) do
    state
      |> State.finished_processing(page.uri)
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
