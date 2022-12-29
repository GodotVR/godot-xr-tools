class_name XRToolsResourceQueue
extends Node


## XRTools Threaded Resource Loader
##
## This class can be used to perform resource loading in the background without
## interrupting the application.


# Thread to perform the loading
var _thread : Thread

# Mutex for safe synchronization
var _mutex : Mutex

# Semaphore to wake up the loader thread
var _semaphore : Semaphore

# Thread exit flag
var _exit_thread : bool = false

# Queue of ResourceInteractiveLoader instances loading resources
var _queue = []

# Dictionary of pending results by resource path.
#
# If the resource is still loading then the value is a ResourceInteractiveLoader.
# If the resource has loaded then the value is a Resource.
var _pending = {}


## Queue the loading of a resource
func queue_resource(path : String, p_in_front : bool = false) -> void:
	# Lock the synchronization mutex
	_mutex.lock()

	# Test if the resource has already been queued
	if path in _pending:
		# Work already queued, nothing to do.
		_mutex.unlock()
		return

	# Test if the ResourceLoader already has it cached
	if ResourceLoader.has_cached(path):
		# Put the resource in the pending-results dictionary
		_pending[path] = ResourceLoader.load(path)
		_mutex.unlock()
		return

	# Construct a ResourceInteractiveLoader for the resource
	var loader = ResourceLoader.load_interactive(path)

	# Save the resource path in the metadata for later use
	loader.set_meta("path", path)

	# Insert into the loading-queue (front for high priority)
	if p_in_front:
		_queue.push_front(loader)
	else:
		_queue.push_back(loader)

	# Save the loader in the pending-results dictionary
	_pending[path] = loader

	# Post the semaphore to wake the worker thread
	_mutex.unlock()
	_semaphore.post()


## Cancel loading a resource
func cancel_resource(path : String) -> void:
	# Lock the synchronization mutex
	_mutex.lock()

	# Inspect the pending-results dictionary
	if path in _pending:
		# Extract the item from the pending-results dictionary
		var item = _pending[path]
		_pending.erase(path)

		# If the item is still being loaded then remove it from the loading-queue
		if item is ResourceInteractiveLoader:
			_queue.erase(item)

	# Loading cancelled
	_mutex.unlock()


## Get the progress of a loading resource
func get_progress(path : String) -> float:
	# Lock the synchronization mutex
	_mutex.lock()

	# Inspect the pending results dictionary for the progress
	var progress := -1.0
	if path in _pending:
		var item = _pending[path]
		if item is ResourceInteractiveLoader:
			# The item is still loading, calculate the progress
			progress = float(item.get_stage()) / float(item.get_stage_count())
		else:
			# The item is fully loaded
			progress = 1.0

	# Return the progress
	_mutex.unlock()
	return progress


## Test if a resouece is ready
func is_ready(path : String) -> bool:
	# Lock the synchronization mutex
	_mutex.lock()

	# Inspect the pending results dictionary for the ready status
	var ready := false
	if path in _pending:
		var item = _pending[path]
		ready = not item is ResourceInteractiveLoader

	# Return the ready status
	_mutex.unlock()
	return ready


## Get the resource
func get_resource(path : String) -> Resource:
	# Lock the synchronization mutex
	_mutex.lock()

	# Test if the resource is unknown
	if not path in _pending:
		# Not queued, just load immediately
		_mutex.unlock()
		return ResourceLoader.load(path)

	# Loop waiting for resource to load
	var res
	while true:
		# Get the item from the pending-results dictionary
		res = _pending[path]

		# Detect loading complete
		if res == null or res is Resource:
			break

		# Give thread more time to load the item
		_mutex.unlock()
		OS.delay_usec(16000) # Wait approximately 1 frame.
		_mutex.lock();

	_pending.erase(path)
	_mutex.unlock()
	return res


## Start the resource queue
func start():
	_mutex = Mutex.new()
	_semaphore = Semaphore.new()
	_thread = Thread.new()
	_thread.start(self, "_thread_func", 0)


# Triggered by calling "get_tree().quit()".
func _exit_tree():
	_mutex.lock()
	_exit_thread = true # Protect with Mutex.
	_mutex.unlock()

	# Wake the worker thread
	_semaphore.post()

	# Wait until it exits.
	_thread.wait_to_finish()


# Thread worker function
func _thread_func(_u):
	# Lock the synchronization mutex
	_mutex.lock()

	# Loop processing work
	while true:
		# Handle a request to terminate
		if _exit_thread:
			_mutex.unlock()
			return

		# Handle no work
		if _queue.size() == 0:
			# Wait for work (with the mutex unlocked so work can be added)
			_mutex.unlock()
			_semaphore.wait()
			_mutex.lock()
			continue

		# Get the loader
		var loader : ResourceInteractiveLoader = _queue.front()

		# Poll the loader (with the mutex unlocked)
		_mutex.unlock()
		var err = loader.poll()
		_mutex.lock()

		# If loader is still busy then continue
		if err == OK:
			continue

		# Remove from the loading-queue. Note that something may have been
		# put at the front of the queue while we polled, so use erase instead
		# of remove
		_queue.erase(loader)

		# Get the resource path from the loaders metadata
		var path : String = loader.get_meta("path")

		# If the result is still pending then update it with the resource
		if path in _pending:
			_pending[path] = loader.get_resource()
