import 'package:chatbond_api/src/invitations/serializer/invitation.dart';

class PaginatedInvitationList {
  PaginatedInvitationList({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory PaginatedInvitationList.fromJson(Map<String, dynamic> json) {
    return PaginatedInvitationList(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: List<Invitation>.from(
        json['results']
                .map((x) => Invitation.fromJson(x as Map<String, dynamic>))
            as Iterable<Invitation>,
      ),
    );
  }

  final int count;
  final String? next;
  final String? previous;
  final List<Invitation> results;
}
