class TourTip {
  final String id;
  final String title;
  final String description;
  final String pageId;
  final int order;

  const TourTip({
    required this.id,
    required this.title,
    required this.description,
    required this.pageId,
    this.order = 0,
  });
}
