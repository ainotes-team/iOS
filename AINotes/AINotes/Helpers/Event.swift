class Event<T> {
    private var eventHandlers = [(T) -> ()]()
    
    func addHandler(handler: @escaping (T) -> ()) {
        eventHandlers.append(handler)
    }
    
    func raise(data: T) {
        for handler in eventHandlers {
            handler(data)
        }
    }
}
