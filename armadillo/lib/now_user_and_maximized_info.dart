// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'important_info.dart';
import 'now_minimization_model.dart';
import 'now_user_image.dart';
import 'quick_settings_progress_model.dart';
import 'user_context_text.dart';

typedef Widget _QuickSettingsTextBuilder(Color color);

/// Displays the user and maximized quick settings text.
class NowUserAndMaximizedContext extends StatelessWidget {
  /// Called when the user's context text is tapped.
  final VoidCallback onUserContextTapped;

  /// Called when the user image is tapped.
  final VoidCallback onUserTapped;

  /// Constructor.
  NowUserAndMaximizedContext({this.onUserContextTapped, this.onUserTapped});

  @override
  Widget build(BuildContext context) =>
      new ScopedModelDescendant<NowMinimizationModel>(
        builder: (
          BuildContext context,
          Widget child,
          NowMinimizationModel nowMinimizationModel,
        ) =>
            new Container(
              height: nowMinimizationModel.userImageDiameter,
              child: new Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // User Context Text when maximized.
                  new Expanded(
                    child: new GestureDetector(
                      onTap: onUserContextTapped,
                      behavior: HitTestBehavior.opaque,
                      child: _buildQuickSettingsText(
                        startingXOffset: -16.0,
                        slideInProgress:
                            nowMinimizationModel.maximizedTextSlideInProgress,
                        builder: (Color color) =>
                            new UserContextText(textColor: color),
                      ),
                    ),
                  ),
                  // User Profile image
                  new NowUserImage(
                    onTap: onUserTapped,
                  ),
                  // Important Information when maximized.
                  new Expanded(
                    child: _buildQuickSettingsText(
                      startingXOffset: 16.0,
                      slideInProgress:
                          nowMinimizationModel.maximizedTextSlideInProgress,
                      builder: (Color color) =>
                          new ImportantInfo(textColor: color),
                    ),
                  ),
                ],
              ),
            ),
      );

  Widget _buildQuickSettingsText({
    double startingXOffset,
    double slideInProgress: 1.0,
    _QuickSettingsTextBuilder builder,
  }) =>
      new Opacity(
        opacity: slideInProgress,
        child: new ScopedModelDescendant<QuickSettingsProgressModel>(
          builder: (
            BuildContext context,
            Widget child,
            QuickSettingsProgressModel quickSettingsProgressModel,
          ) =>
              new Transform(
                transform: new Matrix4.translationValues(
                  lerpDouble(startingXOffset, 0.0, slideInProgress),
                  lerpDouble(0.0, 32.0, quickSettingsProgressModel.value),
                  0.0,
                ),
                child: builder(
                  Color.lerp(
                    Colors.white,
                    Colors.grey[600],
                    quickSettingsProgressModel.value,
                  ),
                ),
              ),
        ),
      );
}
