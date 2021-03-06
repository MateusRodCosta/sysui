// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:lib.suggestion.fidl/proposal.fidl.dart';
import 'package:lib.suggestion.fidl/query_handler.fidl.dart';
import 'package:lib.suggestion.fidl/suggestion_display.fidl.dart';
import 'package:lib.suggestion.fidl/user_input.fidl.dart';
import 'package:lib.agent.fidl/agent_provider.fidl.dart';
import 'package:lib.story.fidl/link.fidl.dart';
import 'package:lib.story.fidl/story_controller.fidl.dart';
import 'package:lib.story.fidl/story_info.fidl.dart';
import 'package:lib.story.fidl/story_provider.fidl.dart';
import 'package:lib.story.fidl/story_state.fidl.dart';
import 'package:lib.user.fidl/focus.fidl.dart';
import 'package:lib.user.fidl/user_shell.fidl.dart';
import 'package:lib.user_intelligence.fidl/intelligence_services.fidl.dart';
import 'package:lib.logging/logging.dart';

/// Manages the list of active agents and the proposals for showing them.
class ActiveAgentsManager {
  final _ActiveAgentProposer _activeAgentProposer = new _ActiveAgentProposer();

  final AgentProviderProxy _agentProvider = new AgentProviderProxy();

  final _AgentProviderWatcherImpl _agentProviderWatcherImpl =
      new _AgentProviderWatcherImpl(
    link: new LinkProxy(),
  );

  final AgentProviderWatcherBinding _agentProviderWatcherBinding =
      new AgentProviderWatcherBinding();

  _CustomAction _customAction;

  /// Starts listening for active agent changes and begins proposing the agent
  /// module be run.
  void start(
    UserShellContext userShellContext,
    FocusProvider focusProvider,
    StoryProvider storyProvider,
    IntelligenceServices intelligenceServices,
  ) {
    userShellContext.getAgentProvider(_agentProvider.ctrl.request());
    _agentProvider.watch(
      _agentProviderWatcherBinding.wrap(_agentProviderWatcherImpl),
    );

    _customAction = new _CustomAction(
      storyProvider: storyProvider,
      agentProviderWatcherImpl: _agentProviderWatcherImpl,
      focusProvider: focusProvider,
    );

    _activeAgentProposer.start(
      intelligenceServices: intelligenceServices,
      customAction: _customAction,
    );
  }

  /// Closes any open handles.
  void stop() {
    _customAction.stop();
    _activeAgentProposer.stop();
    _agentProviderWatcherBinding.close();
    _agentProvider.ctrl.close();
    _agentProviderWatcherImpl.link.ctrl.close();
  }
}

class _AgentProviderWatcherImpl extends AgentProviderWatcher {
  final LinkProxy link;
  final List<String> agents = <String>[];

  _AgentProviderWatcherImpl({this.link});

  @override
  void onUpdate(List<String> agentUrls) {
    agents
      ..clear()
      ..addAll(agentUrls);
    log.fine('agent urls: $agentUrls');
    link.set(null, JSON.encode(agentUrls));
  }
}

class _ActiveAgentProposer {
  final QueryHandlerBinding _queryHandlerBinding = new QueryHandlerBinding();
  _QueryHandlerImpl _queryHandlerImpl;

  void start({
    IntelligenceServices intelligenceServices,
    CustomAction customAction,
  }) {
    _queryHandlerImpl = new _QueryHandlerImpl(
      customAction: customAction,
    );
    intelligenceServices.registerQueryHandler(
      _queryHandlerBinding.wrap(
        _queryHandlerImpl,
      ),
    );
  }

  void stop() {
    _queryHandlerImpl.stop();
    _queryHandlerBinding.close();
  }
}

class _QueryHandlerImpl extends QueryHandler {
  final Set<CustomActionBinding> _bindings = new Set<CustomActionBinding>();

  final CustomAction customAction;

  _QueryHandlerImpl({this.customAction});

  @override
  void onQuery(UserInput query, void callback(QueryResponse response)) {
    List<Proposal> proposals = <Proposal>[];

    if ((query.text?.toLowerCase()?.startsWith('act') ?? false) ||
        (query.text?.toLowerCase()?.startsWith('age') ?? false) ||
        (query.text?.toLowerCase()?.contains('agent') ?? false) ||
        (query.text?.toLowerCase()?.contains('active') ?? false)) {
      CustomActionBinding binding = new CustomActionBinding();
      _bindings.add(binding);
      proposals.add(
        new Proposal()
          ..id = 'View Active Agents'
          ..display = (new SuggestionDisplay()
            ..headline = 'View Active Agents'
            ..subheadline = ''
            ..details = ''
            ..color = 0xFFA5A700
            ..iconUrls = <String>['/system/data/sysui/AgentIcon.png']
            ..imageType = SuggestionImageType.other
            ..imageUrl = ''
            ..annoyance = AnnoyanceType.none)
          ..onSelected = <Action>[
            new Action()..customAction = binding.wrap(customAction)
          ],
      );
    }
    callback(new QueryResponse()..proposals = proposals);
  }

  void stop() {
    for (CustomActionBinding binding in _bindings) {
      binding.close();
    }
  }
}

class _CustomAction extends CustomAction {
  final StoryProvider storyProvider;
  final FocusProvider focusProvider;
  final _AgentProviderWatcherImpl agentProviderWatcherImpl;
  StoryControllerProxy storyControllerProxy;

  _CustomAction({
    this.storyProvider,
    this.focusProvider,
    this.agentProviderWatcherImpl,
  });

  @override
  void execute(void callback(List<Action> actions)) {
    stop();

    storyProvider.createStoryWithInfo(
      'link_viewer',
      <String, String>{'color': '0xFFA5A700'},
      JSON.encode(
        <String, List<String>>{
          'Active Agents': agentProviderWatcherImpl.agents
        },
      ),
      (String storyId) {
        storyControllerProxy = new StoryControllerProxy();
        storyProvider.getController(
          storyId,
          storyControllerProxy.ctrl.request(),
        );
        storyControllerProxy.getInfo((StoryInfo info, StoryState state) {
          focusProvider.request(info.id);
          storyControllerProxy.getLink(
            <String>[],
            'root',
            agentProviderWatcherImpl.link.ctrl.request(),
          );
          callback(null);
          storyControllerProxy?.ctrl?.close();
          storyControllerProxy = null;
        });
      },
    );
  }

  void stop() {
    storyControllerProxy?.ctrl?.close();
    storyControllerProxy = null;
  }
}
