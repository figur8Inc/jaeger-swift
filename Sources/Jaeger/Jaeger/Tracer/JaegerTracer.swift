//
//  JaegerTracer.swift
//  Jaeger
//
//  Created by Simon-Pierre Roy on 11/7/18.
//

import Foundation
import JavaScriptCore

public final class JsUUID {
    let jsSource = "var _generateUUID = function _generateUUID() { var p0 = \"00000000\" + Math.abs((Math.random() * 0xFFFFFFFF) | 0).toString(16); var p1 = \"00000000\" + Math.abs((Math.random() * 0xFFFFFFFF) | 0).toString(16); return p0.substr(-8) + p1.substr(-8);}"
    var context = JSContext()
    let genUUIDFunction: JSValue
    
    
    init() {
        context!.evaluateScript(jsSource)
        genUUIDFunction = (context?.objectForKeyedSubscript("_generateUUID"))!
    }
    
    func _id() -> String! {
        return genUUIDFunction.call(withArguments: [])?.toString()
    }
    
}

let JsUUIDGenerator = JsUUID()

/// A tracer for Jaeger spans.
public typealias JaegerTracer = BasicTracer

/// A tracer using a generic agent for the caching process.
public final class BasicTracer: Tracer {

    /// A fixed id for the tracer.
    let tracerIdHigh = JsUUIDGenerator._id()
    let tracerIdLow = JsUUIDGenerator._id()
    /// The agent used for the caching process.
    private let agent: Agent

    /**
     Creates a new tracer with a unique identifier.
     
     - Parameter agent: The agent used for the caching process.
     */
    init(agent: Agent) {
        self.agent = agent
    }

    /**
     A point of entry the crete a start a new span wrapped in an OTSpan.
     
     - Parameter operationName: A human-readable string which concisely represents the work done by the Span. See [OpenTracing Semantic Specification](https://opentracing.io/specification/) for the naming conventions.
     - Parameter referencing: The relationship to a node (span).
     - Parameter startTime: The time at which the task was started.
     - Parameter tags: Tags to be included at the creation of the span.
     
     - Returns: A new `Span` wrapped in an OTSpan.
     */
    public func startSpan(operationName: String, referencing reference: Span.Reference?, startTime: Date, tags: [Tag]) -> OTSpan {

        let span = Span(
            tracer: self,
            spanRef: .init(traceIdHigh: self.tracerIdHigh!, traceIdLow: self.tracerIdLow!, spanId: JsUUIDGenerator._id()),
            parentSpanRef: reference,
            operationName: operationName,
            flag: .sampled,
            startTime: startTime,
            tags: [:],
            logs: []
        )

        return OTSpan(span: span)
    }

    /**
     Transfer a **completed** span to the tracer.
     
     - Parameter span: A **completed** span.
     */
    public func report(span: Span) {
        self.agent.record(span: span)
    }
}
