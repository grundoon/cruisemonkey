import 'dart:async';
import 'dart:typed_data';

import 'package:cruisemonkey/src/basic_types.dart';
import 'package:cruisemonkey/src/logic/cruise.dart';
import 'package:cruisemonkey/src/logic/forums.dart';
import 'package:cruisemonkey/src/logic/photo_manager.dart';
import 'package:cruisemonkey/src/logic/seamail.dart';
import 'package:cruisemonkey/src/logic/store.dart';
import 'package:cruisemonkey/src/logic/stream.dart';
import 'package:cruisemonkey/src/models/announcements.dart';
import 'package:cruisemonkey/src/models/calendar.dart';
import 'package:cruisemonkey/src/models/server_text.dart';
import 'package:cruisemonkey/src/models/user.dart';
import 'package:cruisemonkey/src/network/twitarr.dart';
import 'package:cruisemonkey/src/progress.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'nulls.dart' show NullTwitarrConfiguration;

class TrivialDataStore implements DataStore {
  TrivialDataStore(this.log);

  final List<String> log;

  Credentials storedCredentials;

  @override
  Progress<void> saveCredentials(Credentials value) {
    log.add('LoggingDataStore.saveCredentials $value');
    return Progress<void>.completed(null);
  }

  @override
  Progress<Credentials> restoreCredentials() {
    log.add('LoggingDataStore.restoreCredentials');
    return Progress<Credentials>.completed(storedCredentials);
  }

  Map<Setting, dynamic> storedSettings = <Setting, dynamic>{};

  @override
  Progress<void> saveSetting(Setting id, dynamic value) {
    log.add('LoggingDataStore.saveSetting $id $value');
    storedSettings[id] = value;
    return Progress<void>.completed(null);
  }

  @override
  Progress<Map<Setting, dynamic>> restoreSettings() {
    log.add('LoggingDataStore.restoreSettings');
    return Progress<Map<Setting, dynamic>>.completed(storedSettings);
  }

  @override
  Progress<dynamic> restoreSetting(Setting id) {
    log.add('LoggingDataStore.restoreSetting $id');
    return Progress<dynamic>.completed(storedSettings[id]);
  }

  Map<String, Set<String>> storedNotifications = <String, Set<String>>{};

  @override
  Future<void> addNotification(String threadId, String messageId) async {
    log.add('LoggingDataStore.addNotification($threadId, $messageId)');
    final Set<String> thread = storedNotifications.putIfAbsent(threadId, () => <String>{});
    thread.add(messageId);
  }

  @override
  Future<void> removeNotification(String threadId, String messageId) async {
    log.add('LoggingDataStore.removeNotification($threadId, $messageId)');
    final Set<String> thread = storedNotifications.putIfAbsent(threadId, () => <String>{});
    thread.remove(messageId);
  }

  @override
  Future<List<String>> getNotifications(String threadId) async {
    log.add('LoggingDataStore.getNotifications($threadId)');
    final Set<String> thread = storedNotifications.putIfAbsent(threadId, () => <String>{});
    return thread.toList();
  }

  int storedFreshnessToken;

  @override
  Future<void> updateFreshnessToken(FreshnessCallback callback) async {
    log.add('LoggingDataStore.updateFreshnessToken');
    storedFreshnessToken = await callback(storedFreshnessToken);
  }

  @override
  Future<void> heardAboutUserPhoto(String id, DateTime updateTime) async { }

  @override
  Future<Uint8List> putImageIfAbsent(String serverKey, String cacheName, String photoId, ImageFetcher callback) async {
    return await callback();
  }

  @override
  Future<void> removeImage(String serverKey, String cacheName, String photoId) async { }

  @override
  Future<Map<String, DateTime>> restoreUserPhotoList() async {
    return <String, DateTime>{};
  }
}

class TestCruiseModel extends ChangeNotifier implements CruiseModel {
  TestCruiseModel({
    MutableContinuousProgress<AuthenticatedUser> user,
    MutableContinuousProgress<Calendar> calendar,
    MutableContinuousProgress<List<Announcement>> announcements,
  }) : user = user ?? MutableContinuousProgress<AuthenticatedUser>(),
       calendar = calendar ?? MutableContinuousProgress<Calendar>(),
       announcements = announcements ?? MutableContinuousProgress<List<Announcement>>() {
    _seamail = Seamail.empty();
    _forums = Forums.empty();
  }

  @override
  final ErrorCallback onError = null;

  @override
  final CheckForMessagesCallback onCheckForMessages = null;

  @override
  final Duration steadyPollInterval = const Duration(minutes: 10);

  @override
  final DataStore store = TrivialDataStore(<String>[]);

  @override
  TwitarrConfiguration get twitarrConfiguration => const NullTwitarrConfiguration();

  @override
  double debugLatency = 0.0;

  @override
  double debugReliability = 1.0;

  @override
  void selectTwitarrConfiguration(TwitarrConfiguration newConfiguration) {
    assert(newConfiguration is NullTwitarrConfiguration);
  }

  @override
  Progress<void> saveTwitarrConfiguration() {
    return const Progress<void>.idle();
  }

  @override
  ValueListenable<bool> get restoringSettings => _restoringSettings;
  final ValueNotifier<bool> _restoringSettings = ValueNotifier<bool>(false);

  @override
  Seamail get seamail => _seamail;
  Seamail _seamail;

  @override
  Forums get forums => _forums;
  Forums _forums;

  @override
  TweetStream get tweetStream => TweetStream(null, null, photoManager: this);

  @override
  Progress<String> createAccount({
    @required String username,
    @required String password,
    @required String registrationCode,
    String displayName,
  }) {
    return const Progress<String>.idle();
  }

  @override
  Progress<Credentials> login({
    @required String username,
    @required String password,
  }) {
    return const Progress<Credentials>.idle();
  }

  @override
  void retryUserLogin() { }

  @override
  void setAsMod({ @required bool enabled }) { }

  @override
  Progress<Credentials> logout({ bool serverChanging = false }) {
    return const Progress<Credentials>.idle();
  }

  @override
  final MutableContinuousProgress<AuthenticatedUser> user;

  @override
  Progress<User> fetchProfile(String username) {
    return const Progress<User>.idle();
  }

  @override
  bool get isLoggedIn => false;

  @override
  Future<void> get loggedIn async => null;

  @override
  final MutableContinuousProgress<Calendar> calendar;

  @override
  Progress<void> setEventFavorite({
    @required String eventId,
    @required bool favorite,
  }) => null;

  @override
  final MutableContinuousProgress<List<Announcement>> announcements;

  @override
  Progress<ServerText> fetchServerText(String filename) {
    return const Progress<ServerText>.idle();
  }

  @override
  Future<Uint8List> putImageIfAbsent(String username, ImageFetcher callback, { @required bool thumbnail }) {
    return callback();
  }

  @override
  Future<Uint8List> putUserPhotoIfAbsent(String username, ImageFetcher callback) {
    return callback();
  }

  @override
  void heardAboutUserPhoto(String username, DateTime lastUpdate) {
  }

  @override
  void addListenerForUserPhoto(String username, VoidCallback listener) {
  }

  @override
  void removeListenerForUserPhoto(String username, VoidCallback listener) {
  }

  @override
  Widget avatarFor(Iterable<User> users, { double size: 40.0, int seed = 0, bool enabled = true }) => null;

  @override
  ImageProvider imageFor(Photo photo, { bool thumbnail = false }) => null;

  @override
  Progress<void> updateProfile({
    String currentLocation,
    String displayName,
    String realName,
    String pronouns,
    String email,
    bool emailPublic,
    String homeLocation,
    String roomNumber,
    bool vcardPublic,
  }) => null;

  @override
  Progress<void> uploadAvatar({ Uint8List image }) => null;

  @override
  Progress<void> updatePassword({
    @required String oldPassword,
    @required String newPassword,
  }) => null;

  @override
  Progress<List<User>> getUserList(String searchTerm) => null;

  @override
  Progress<void> postTweet({
    @required Credentials credentials,
    @required String text,
    String parentId,
    @required Uint8List photo,
  }) => null;

  @override
  void forceUpdate() { }

  @override
  void dispose() {
    user.dispose();
    calendar.dispose();
    super.dispose();
  }
}
