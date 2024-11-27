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
