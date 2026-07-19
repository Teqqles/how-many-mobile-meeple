import 'package:flutter/material.dart';

/// A single point of guidance within a help section.
class HelpItem {
  final IconData icon;
  final String title;
  final String body;

  const HelpItem({
    required this.icon,
    required this.title,
    required this.body,
  });
}

/// A page-scoped group of help items. [id] matches the page it describes so
/// the help page can scroll straight to the relevant guidance.
class HelpSection {
  final String id;
  final IconData icon;
  final String title;
  final String summary;
  final List<HelpItem> items;

  const HelpSection({
    required this.id,
    required this.icon,
    required this.title,
    required this.summary,
    required this.items,
  });
}

/// Static help content for the whole app. Each section maps to a page via its
/// [HelpSection.id]; the app bar passes that id so help opens in context.
class HelpContent {
  // Section ids - kept in sync with the ids passed by each page's app bar.
  static const String home = 'home';
  static const String list = 'list';
  static const String random = 'random';
  static const String favourites = 'favourites';
  static const String playLog = 'play-log';
  static const String shelfOfShame = 'shelf-of-shame';
  static const String settings = 'settings';
  static const String gameDetail = 'game-detail';

  static const List<HelpSection> sections = [
    HelpSection(
      id: home,
      icon: Icons.home_outlined,
      title: 'Finding Games',
      summary: 'The home screen walks you through five steps to find the right '
          'game for your group. Swipe or tap the step dots to move around - '
          'you can also jump straight to results with Finish or Quick Pick.',
      items: [
        HelpItem(
          icon: Icons.source,
          title: 'Step 1 - Source',
          body: 'Choose where your games come from: Trending pulls the hottest '
              'games on BoardGameGeek (no account needed), Collection searches '
              'your own BGG collection by username, and Geeklist uses a '
              'community list ID. You can add several sources at once and set a '
              'primary player with the crown icon.',
        ),
        HelpItem(
          icon: Icons.people_outline,
          title: 'Step 2 - Players',
          body: 'Set how many people are playing with the slider or a quick '
              'preset. Recommendations are filtered to games that support that '
              'player count.',
        ),
        HelpItem(
          icon: Icons.schedule,
          title: 'Step 3 - Time',
          body: 'Drag the two handles to set the shortest and longest play '
              'time you want. Presets below cover common session lengths.',
        ),
        HelpItem(
          icon: Icons.tune,
          title: 'Step 4 - Style',
          body: 'Set game weight from Light to Expert (leave at 0 for any), '
              'and tap mechanic chips to prefer certain game types. Leave '
              'mechanics unselected to include everything.',
        ),
        HelpItem(
          icon: Icons.check_circle_outline,
          title: 'Step 5 - Results',
          body:
              'From here you can view the full matching list, pick one random '
              'game, or save your current filters to reload later.',
        ),
        HelpItem(
          icon: Icons.bolt,
          title: 'Advanced Mode',
          body: 'Prefer all controls on one screen? Switch to Advanced Mode '
              'from Step 5 or the settings drawer. Toggle "Always Use Advanced '
              'Mode" to make it the default.',
        ),
      ],
    ),
    HelpSection(
      id: list,
      icon: Icons.format_list_numbered,
      title: 'Game List',
      summary:
          'The list shows every game matching your filters, with thumbnails '
          'and ratings.',
      items: [
        HelpItem(
          icon: Icons.swipe,
          title: 'Swipe Actions',
          body: 'Swipe a game right to add it to Favourites, or left to ignore '
              'it so it stays out of future results.',
        ),
        HelpItem(
          icon: Icons.touch_app,
          title: 'Open a Game',
          body:
              'Tap any game to see its full details, including player counts, '
              'play time, and a link to BoardGameGeek.',
        ),
      ],
    ),
    HelpSection(
      id: random,
      icon: Icons.casino,
      title: 'Random Game',
      summary:
          'Beat decision paralysis - this picks one game at random from your '
          'filtered results.',
      items: [
        HelpItem(
          icon: Icons.refresh,
          title: 'Pick Again',
          body: 'Not feeling it? Roll again for another game from the same '
              'filtered set.',
        ),
      ],
    ),
    HelpSection(
      id: favourites,
      icon: Icons.favorite,
      title: 'Favourites & Ignored',
      summary:
          'Your saved and hidden games live here, reachable from the heart '
          'icon and the menu.',
      items: [
        HelpItem(
          icon: Icons.favorite_border,
          title: 'Favourites',
          body: 'Games you swipe right on, or tap the heart on, are saved here '
              'for quick access.',
        ),
        HelpItem(
          icon: Icons.visibility_off_outlined,
          title: 'Ignored Games',
          body: 'Games you swipe left on are hidden from future results. Open '
              'Ignored Games from the menu to restore them.',
        ),
      ],
    ),
    HelpSection(
      id: playLog,
      icon: Icons.history,
      title: 'Play History',
      summary: 'Keep a record of the games you have played and when.',
      items: [
        HelpItem(
          icon: Icons.add,
          title: 'Logging Plays',
          body: 'Record a play from a game detail page. Your history is stored '
              'on this device.',
        ),
      ],
    ),
    HelpSection(
      id: shelfOfShame,
      icon: Icons.shelves,
      title: 'Shelf of Shame',
      summary:
          'Surface the games in your collection you own but have rarely or '
          'never played. Needs a BGG collection added as a source.',
      items: [
        HelpItem(
          icon: Icons.person_outline,
          title: 'Whose Shelf?',
          body: 'The shelf uses your primary player\'s BGG collection. Set the '
              'primary player with the crown icon on Step 1.',
        ),
      ],
    ),
    HelpSection(
      id: settings,
      icon: Icons.settings,
      title: 'Settings & Filters',
      summary: 'The settings drawer (gear icon) holds advanced filters and app '
          'preferences.',
      items: [
        HelpItem(
          icon: Icons.filter_alt_outlined,
          title: 'Advanced Filters',
          body: 'Fine-tune results with options like recommended player-count '
              'filtering, including expansions, and showing all mechanics.',
        ),
        HelpItem(
          icon: Icons.save_outlined,
          title: 'Saved Settings',
          body: 'Save a set of filters so you can reload them in one tap next '
              'time.',
        ),
      ],
    ),
    HelpSection(
      id: gameDetail,
      icon: Icons.info_outline,
      title: 'Game Details',
      summary: 'The detail page shows everything about a single game.',
      items: [
        HelpItem(
          icon: Icons.favorite_border,
          title: 'Save & Log',
          body: 'Tap the heart to favourite a game, and log a play to add it '
              'to your Play History.',
        ),
        HelpItem(
          icon: Icons.open_in_new,
          title: 'View on BGG',
          body: 'Open the game on BoardGameGeek for full rules, images, and '
              'community reviews.',
        ),
      ],
    ),
  ];

  static HelpSection? forId(String? id) {
    if (id == null) return null;
    for (final section in sections) {
      if (section.id == id) return section;
    }
    return null;
  }
}
