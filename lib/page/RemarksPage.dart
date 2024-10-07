import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:xmihoyo/provider/announcement_provider.dart';

class RemarksPage extends StatefulWidget {
  @override
  _RemarksPageState createState() => _RemarksPageState();
}

class _RemarksPageState extends State<RemarksPage> {
  @override
  Widget build(BuildContext context) {
    final announcementProvider = Provider.of<AnnouncementProvider>(context);
    final markedAnnouncements = announcementProvider.markedAnnouncementsData;

    return Scaffold(
      appBar: AppBar(
        title: Text('标记'),
      ),
      body: Column(
        children: [
          ListTile(
            title: Text('取消所有标记 (${markedAnnouncements.length})'),
            trailing: Icon(Icons.clear_all),
            onTap: () {
              setState(() {
                announcementProvider.clearAllMarkedAnnouncements();
              });
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: markedAnnouncements.length,
              itemBuilder: (context, index) {
                var item = markedAnnouncements[index];
                String annId = item['ann_id'].toString();
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('标记的公告ID: $annId'),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  announcementProvider
                                      .removeMarkedAnnouncement(annId);
                                });
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text('公告标题: ${item['title'] ?? "无标题"}'),
                        CachedNetworkImage(
                          imageUrl: item['banner']?.isNotEmpty == true
                              ? item['banner']
                              : item['img'] ?? 'https://example.com.jpg',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) =>
                              Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              Image.asset('assets/placeholder.png'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
