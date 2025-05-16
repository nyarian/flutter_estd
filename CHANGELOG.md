## 0.0.1

* Shipping initial features: ESTD declarations and functionality, IoC, UI, Logging

## 0.0.2

* Added error handling extensions, HTTP extensions, GetIt ServiceLocator implementation and ServiceLocatorWidget

## 0.0.3

* Added Flutter-based navigation extensions

## 0.0.4

* Added Flutter-based logging

## 0.0.5

* Added the Registry abstraction and a SharedPreferences-based implementation

## 0.0.6

* Added ChangeNotifierResource

## 0.0.7

* Added the current value to LambdaMutationGateway's main method

## 0.0.8

* Query parameters are now removed from the `path` in URLPath

## 0.0.9

* Explicit query parameters interface was added to URLPath

## 0.0.10

* Added `ResultBloc` - analogous to `OperationBloc`, but can carries the operation result

## 0.0.11

* Added `AnimationListenerMixinResource`

## 0.0.12

* Added the separate `bloc_result` sub-library

## 0.0.13

* Renamed the Provider to Supplier for ResultBloc, as well as LambdaOperation to LambdaSupplier
* Relaxed the state transition for OperationBloc and ResultBloc: operations can now be ran from ErrorState

## 0.0.14

* Included the `let` extension method
* Expanded PagedBloc to support append / prepend / remove / replace operations as well as configurable item actualization and list differences reconciliation routines

## 0.0.15

* Renamed the "Builder" typedef for BlocBuilder

## 0.0.16

* Add value replacement option for Query

## 0.0.17

* Fix the PagedBloc's default constructor bug regarding the constant type creation with a generic type argument

## 0.0.18

* Publish the "query" property from PageState

## 0.0.19

* Publish the "current" property from PageState, add metadata support to the PagedBloc

## 0.0.20

* Add "NoMetadataPagedGateway"

## 0.0.21

* Add prependAll support for PagedBloc

## 0.0.22

* Make Optional a sealed class to enable pattern matching

## 0.0.23

* Remove the `firstOrNull` and `windowed` iterable extensions

## 0.0.24

* Add the `parent()` method to URLPath

## 0.0.25

* Change the `ApplicationRouter`'s `location` type to `URLPath`

## 0.0.26

* Make the `Log`'s `trace` nullable

## 0.0.27

* Add the `http` dependency
* Exclude `http`'s `ClientException` from crash causes
* Add minimal versions for all the transitive dependencies

## 0.0.28

* Make StreamTransformerBloc safe in terms of event addition

## 0.0.29

* Relax the ResultBloc's state transitions (allow success -> processing)

## 0.0.30

* Add safe error clear option for MutationBloc

## 0.0.31

* Add `maxLines` and `overflow` as parameters to `DynamicSpanText`

## 0.0.32

* Fix `HttpServiceUri` to parse subpaths properly

## 0.0.33

* Publish the stream transformer as a constructor property for PageBloc

## 0.0.34

* Add concurrency support to PagedBloc (graceful FetchedState transition for non-loading states)

## 0.0.35

* Add the current state to MutationBloc#Gateway#Fetch
