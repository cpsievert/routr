% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/routestack.R
\docType{data}
\name{RouteStack}
\alias{RouteStack}
\title{Combine multiple routes for sequential routing}
\description{
The \code{RouteStack} class encapsulate multiple \link{Route}s and lets a request be
passed through each sequentially. If a route is returning \code{FALSE} upon
dispatch further dispatching is cancelled.
}
\section{Initialization}{

A new 'RouteStack'-object is initialized using the \code{new()} method on the
generator:

\strong{Usage}
\tabular{l}{
\code{route <- RouteStack$new(..., path_extractor = function(msg, bin) '/')}
}

\strong{Arguments}
\tabular{lll}{
\code{...} \tab  \tab Routes to add up front. Must be in the form of named
arguments containing \code{Route} objects. \cr
\code{path_extractor} \tab  \tab A function that returns a path to dispatch
on from a WebSocket message. Will only be used if
\code{attach_to == 'message'}. Defaults to a function returning \code{'/'}
}
}

\section{Field}{

The following fields are accessible in a \code{RouteStack} object:

\describe{
\item{\code{attach_to}}{Either \code{"request"} (default), \code{"header"}, or \code{"message"}
that defines which event the router should be attached to when used as a
\code{fiery} plugin.}
\item{\code{name}}{The plugin name (used by \code{fiery}). Will return \code{'&lt;attach_to&gt;_routr'} (e.g. \code{'request_routr'} if \code{attach_to == 'request'})}
}
}

\section{Methods}{

The following methods are accessible in a \code{RouteStack} object:

\describe{
\item{\code{add_route(route, name, after = NULL)}}{Adds a new route to the stack.
\code{route} must be a \code{Route} object, \code{name} must be a string. If \code{after} is
given the route will be inserted after the given index, if not (or \code{NULL})
it will be inserted in the end of the stack.}
\item{\code{has_route(name)}}{Test if the routestack contains a route with the
given name.}
\item{\code{remove(name)}}{Removes the route with the given name from the stack.}
\item{\code{dispatch(request, ...)}}{Passes a \link[reqres:Request]{reqres::Request} through the stack
of routes in sequence until one of the routes return \code{FALSE} or every route
have been passed through. \code{...} will be passed on to the dispatch of each
\code{Route} on the stack.}
\item{\code{on_error(fun)}}{Set the error handling function. This must be a
function that accepts an \code{error}, \code{request}, and \code{reponse} argument. The
error handler will be called if any of the route handlers throws an error
and can be used to modify the \code{500} response before it is send back. By
default, the error will be signaled using \code{message}}
\item{\code{on_attach(app, on_error = NULL, ...)}}{Method for use by \code{fiery} when
attached as a plugin. Should not be called directly.}
}
}

\section{Fiery plugin}{

A \code{RouteStack} object is a valid \code{fiery} plugin and can thus be passed in to
the \code{attach()} method of a \code{Fire} object. When used as a fiery plugin it is
important to be concious for what event it is attached to. By default it will
be attached to the \code{request} event and thus be used to handle HTTP request
messaging. An alternative is to attach it to the \code{header} event that is fired
when all headers have been recieved but before the body is. This allows you
to short-circuit request handling and e.g. reject requests above a certain
size. When the router is attached to the \code{header} event any handler returning
\code{FALSE} will signal that further handling of the request should be stopped
and the response in its current form should be returned without fetching the
request body.

One last possibility is to attach it to the \code{message} event and thus use it
to handle WebSocket messages. This use case is a bit different from that of
\code{request} and \code{header}. As \code{routr} uses \code{Request} objects as a vessel between
routes and WebSocket messages are not HTTP requests, some modification is
needed. The way \code{routr} achieves this is be modifying the HTTP request that
established the WebSocket connection and send this through the routes. Using
the \code{path_extractor} function provided in the \code{RouteStack} constructor it
will extract a path to dispatch on and assign it to the request. Furthermore
it assigns the message to the body of the request and sets the \code{Content-Type}
header based on whether the message is binary \code{application/octet-stream} or
not \code{text/plain}. As WebSocket communication is asynchronous the response is
ignored when attached to the \code{message} event. If communication should be send
back, use \code{server$send()} inside the handler(s).

How a \code{RouteStack} is attached is defined by the \code{attach_to} field which must
be either \code{'request'}, \code{'header'}, or \code{'message'}.

When attaching the \code{RouteStack} it is possible to modify how errors are
handled, using the \code{on_error} argument, which will change the error handler
set on the \code{RouteStack}. By default the error handler will be changed to
using the \code{fiery} logging system if the \code{Fire} object supports it.
}

\examples{
# Create a new stack
routes <- RouteStack$new()

# Populate it wih routes
first <- Route$new()
first$add_handler('all', '*', function(request, response, keys, ...) {
  message('This will always get called first')
  TRUE
})
second <- Route$new()
second$add_handler('get', '/demo/', function(request, response, keys, ...) {
  message('This will get called next if the request asks for /demo/')
  TRUE
})
routes$add_route(first, 'first')
routes$add_route(second, 'second')

# Send a request through
rook <- fiery::fake_request('http://example.com/demo/', method = 'get')
req <- reqres::Request$new(rook)
routes$dispatch(req)

}
\seealso{
\link{Route} for defining single routes
}
\keyword{datasets}
