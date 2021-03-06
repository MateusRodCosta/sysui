// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';

import 'conductor.dart';
import 'idle_mode_builder.dart';
import 'next_builder.dart';
import 'now/now_builder.dart';
import 'recents_builder.dart';
import 'story.dart';

export 'package:lib.widgets/model.dart'
    show ScopedModel, Model, ScopedModelDescendant;

/// Provides builders for Conductor.
class ConductorModel extends Model {
  final GlobalKey<ConductorState> _conductorKey =
      new GlobalKey<ConductorState>();
  final IdleModeBuilder _idleModeBuilder = new IdleModeBuilder();
  final NowBuilder _nowBuilder = new NowBuilder();
  final RecentsBuilder _recentsBuilder = new RecentsBuilder();
  final NextBuilder _nextBuilder = new NextBuilder();

  /// Wraps [ModelFinder.of] for this [Model]. See [ModelFinder.of] for more
  /// details.
  static ConductorModel of(BuildContext context) =>
      new ModelFinder<ConductorModel>().of(context);

  /// Builds the idle mode.
  IdleModeBuilder get idleModeBuilder => _idleModeBuilder;

  /// Builds now.
  NowBuilder get nowBuilder => _nowBuilder;

  /// Builds recents.
  RecentsBuilder get recentsBuilder => _recentsBuilder;

  /// Builds next.
  NextBuilder get nextBuilder => _nextBuilder;

  /// Moves the conductor to its original layout.
  void goToOrigin() {
    _conductorKey.currentState.goToOrigin();
  }

  /// Focuses the given story.
  void focusStory(String storyId) {
    scheduleMicrotask(() {
      _conductorKey.currentState.requestStoryFocus(
        new StoryId(storyId),
        jumpToFinish: true,
      );
    });
  }

  /// Builds the conductor.
  Widget build() => new Conductor(key: _conductorKey);
}
