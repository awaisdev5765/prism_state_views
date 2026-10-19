/// One widget for empty, loading, error, and success states in Flutter.
///
/// Built around Dart 3 sealed classes so the compiler enforces that every
/// state is handled. See [PrismStateView] and [PrismViewState].
library;

export 'src/state.dart'
    show
        PrismViewEmpty,
        PrismViewError,
        PrismViewLoading,
        PrismViewSuccess,
        PrismViewState,
        PrismViewStateNotifier;
export 'src/state_view.dart' show PrismStateView;
export 'src/style.dart' show PrismStateViewStyle;
