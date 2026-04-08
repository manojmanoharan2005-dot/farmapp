class ListItem {
  final String id;
  final String title;
  final String subtitle;
  final String status;

  const ListItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.status = '',
  });
}
