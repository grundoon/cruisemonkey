import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../progress.dart';
import '../widgets.dart';

typedef bool Filter<T>(T element);

class KaraokeView extends StatefulWidget implements View {
  const KaraokeView({
    Key key,
  }) : super(key: key);

  @override
  Widget buildTabIcon(BuildContext context) => const Icon(Icons.library_music);

  @override
  Widget buildTabLabel(BuildContext context) => const Text('Karaoke');

  @override
  Widget buildFab(BuildContext context) {
    return null;
  }

  @visibleForTesting
  static Progress<void> get loadStatus {
    return Progress.convert<List<Song>, void>(_KaraokeViewState._songs, (List<Song> songs) => null);
  }

  @override
  _KaraokeViewState createState() => _KaraokeViewState();
}

class _KaraokeViewState extends State<KaraokeView> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initSongs(DefaultAssetBundle.of(context));
  }

  static String catalogResource = 'resources/JoCoKaraokeSongCatalog.txt';
  static Progress<List<Song>> _songs;
  static AssetBundle _songBundle;

  static bool _initStarted = false;
  void initSongs(AssetBundle bundle) async {
    // TODO(ianh): This doesn't support handling the case of the asset bundle
    // changing, since we only run it once even if the bundle is different.
    // (that should only matter for tests though, in normal execution the bundle won't change)
    if (_initStarted) {
      assert(_songBundle == bundle);
      assert(_songs != null);
      return;
    }
    assert(_songBundle == null);
    assert(_songs == null);
    _initStarted = true;
    _songBundle = bundle;
    _songs = Progress<List<Song>>((ProgressController<List<Song>> completer) async {
      return await bundle.loadStructuredData<List<Song>>(
        catalogResource,
        (String data) => compute<String, List<Song>>(_parser, data),
      );
    });
  }

  static List<Song> _parser(String data) {
    final List<String> lines = data.split('\n');
    final List<Song> songs = <Song>[];
    for (String line in lines) {
      final List<String> parts = line.split('\t');
      if (parts.length >= 2)
        songs.add(Song(parts[1], parts[0], parts.length > 2 ? parts[2] : ''));
    }
    songs.sort();
    return songs;
  }

  Filter<Song> _filter;
  final ScrollController _scrollController = ScrollController();

  void _applyFilter(String query) {
    setState(() {
      query = query.trim();
      if (query.isEmpty) {
        _filter = null;
      } else {
        final List<String> keywords = query.toLowerCase().split(' ');
        _filter = (Song song) => song.matches(keywords);
      }
      _scrollController.jumpTo(0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textStyle = Theme.of(context).textTheme;
    return ProgressBuilder<List<Song>>(
      progress: _songs,
      builder: (BuildContext context, List<Song> songList) {
        if (_filter != null)
          songList = songList.where(_filter).toList();
        final EdgeInsets outerPadding = MediaQuery.of(context).padding;
        return Column(
          children: <Widget>[
            Material(
              elevation: 4.0,
              child: Padding(
                padding: outerPadding.copyWith(bottom: 0.0) + const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    suffixIcon: Icon(Icons.search),
                  ),
                  onChanged: _applyFilter,
                ),
              ),
            ),
            Expanded(
              child: Scrollbar(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: outerPadding.copyWith(top: 0.0) + const EdgeInsets.all(8.0),
                  itemCount: songList.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Song song = songList[index];
                    Widget trailing;
                    switch (song.metadata) {
                      case 'M':
                        trailing = Text('M', style: textStyle.caption);
                        break;
                      case 'VR':
                        trailing = Text('VR', style: textStyle.caption);
                        break;
                      // 'Bowieoke' seems to mean "David Bowie sang this",
                      // which is already reflected in the artist, so...
                    }
                    return ListTile(
                      title: Text(song.title),
                      subtitle: Text(song.artist),
                      trailing: trailing,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class Song implements Comparable<Song> {
  const Song(this.title, this.artist, this.metadata);

  final String title;
  final String artist;
  final String metadata;

  @override
  int compareTo(Song other) {
    if (title == other.title)
      return artist.compareTo(other.artist);
    return title.compareTo(other.title);
  }

  bool matches(List<String> substrings) {
    return substrings.every(
      (String substring) {
        return title.toLowerCase().contains(substring)
            || artist.toLowerCase().contains(substring);
      },
    );
  }
}
