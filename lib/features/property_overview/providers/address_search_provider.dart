import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/services/nominatim_service.dart';
import '../data/models/nominatim_result.dart';

class AddressSearchState {
  final String query;
  final List<NominatimResult> suggestions;
  final bool isLoading;
  final String? error;

  const AddressSearchState({
    this.query = '',
    this.suggestions = const [],
    this.isLoading = false,
    this.error,
  });

  AddressSearchState copyWith({
    String? query,
    List<NominatimResult>? suggestions,
    bool? isLoading,
    String? error,
  }) {
    return AddressSearchState(
      query: query ?? this.query,
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AddressSearchNotifier extends Notifier<AddressSearchState> {
  Timer? _debounceTimer;
  final NominatimService _service = NominatimService();

  static const int _minChars = 3;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  @override
  AddressSearchState build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return const AddressSearchState();
  }

  void updateQuery(String query) {
    _debounceTimer?.cancel();

    state = state.copyWith(query: query, error: null);

    if (query.trim().length < _minChars) {
      state = state.copyWith(suggestions: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);

    _debounceTimer = Timer(_debounceDuration, () async {
      try {
        final results = await _service.searchAddress(query);
        if (state.query == query) {
          state = state.copyWith(suggestions: results, isLoading: false);
        }
      } catch (_) {
        if (state.query == query) {
          state = state.copyWith(
            isLoading: false,
            suggestions: [],
            error: 'Search failed. Please try again.',
          );
        }
      }
    });
  }

  void clear() {
    _debounceTimer?.cancel();
    state = const AddressSearchState();
  }
}

final addressSearchProvider =
    NotifierProvider.autoDispose<AddressSearchNotifier, AddressSearchState>(
      AddressSearchNotifier.new,
    );
