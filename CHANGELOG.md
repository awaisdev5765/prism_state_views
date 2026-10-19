# Changelog

## 0.1.0

- Initial release.
- `PrismViewState<T>` sealed class: loading, error, empty, success.
- `PrismStateView` widget with retry and empty-action callbacks and animated
  state transitions.
- `PrismViewStateNotifier.fromFuture` for non-Riverpod/BLoC apps.
- `PrismStateViewStyle` for theming.
