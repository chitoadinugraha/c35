import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/mail/mail_models.dart' as models;
import 'package:alienai_c35/c/pb/c35/mail.pb.dart' as pb;
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:fixnum/fixnum.dart';

class MailApi {
  MailApi(this.conn);

  final ChatConn conn;

  Future<models.MailAccount> accountGet() async {
    final res = await conn.rpc(WsReq(mailAccountGet: pb.ReqMailAccountGet()), (r) => r.mailAccountGet);
    final a = res.account;
    return models.MailAccount(uid: a.ownerIid.toInt(), address: a.address, createdAt: a.createdTsMs.toInt(), mailboxId: a.mailboxId.toInt());
  }

  Future<List<models.MailMailbox>> mailboxList() async {
    final res = await conn.rpc(WsReq(mailMailboxList: pb.ReqMailMailboxList()), (r) => r.mailMailboxList);
    return res.mailboxes.map(_mailboxFromPb).toList();
  }

  Future<List<models.MailMailbox>> mailboxAdminList() async {
    final res = await conn.rpc(WsReq(mailMailboxAdminList: pb.ReqMailMailboxAdminList()), (r) => r.mailMailboxAdminList);
    return res.mailboxes.map(_mailboxFromPb).toList();
  }

  Future<List<models.MailDomain>> domainList() async {
    final res = await conn.rpc(WsReq(mailDomainList: pb.ReqMailDomainList()), (r) => r.mailDomainList);
    return res.domains.map(_domainFromPb).toList();
  }

  Future<List<models.MailMessage>> list({
    required models.MailDirection direction,
    int mailboxId = 0,
    int limit = 50,
    int beforeMessageId = 0,
    bool isArchived = false,
  }) async {
    final res = await conn.rpc(
      WsReq(
        mailList: pb.ReqMailList(
          direction: direction == models.MailDirection.inbound ? pb.MailDirection.MAIL_DIRECTION_IN : pb.MailDirection.MAIL_DIRECTION_OUT,
          limit: limit,
          beforeMessageId: Int64(beforeMessageId),
          mailboxId: Int64(mailboxId),
          isArchived: isArchived,
        ),
      ),
      (r) => r.mailList,
    );
    return res.messages.map(_messageFromPb).toList();
  }

  Future<models.MailMessage> get(int messageId, {int mailboxId = 0}) async {
    final res = await conn.rpc(
      WsReq(mailGet: pb.ReqMailGet(messageId: Int64(messageId), mailboxId: Int64(mailboxId))),
      (r) => r.mailGet,
    );
    return _messageFromPb(res.message);
  }

  Future<models.MailMessage> send({
    int mailboxId = 0,
    required String toAddr,
    required String subject,
    required String bodyText,
    String bodyHtml = '',
    List<models.MailAttachment> attachments = const [],
  }) async {
    final res = await conn.rpc(
      WsReq(
        mailSend: pb.ReqMailSend(
          mailboxId: Int64(mailboxId),
          toAddr: toAddr,
          subject: subject,
          bodyText: bodyText,
          bodyHtml: bodyHtml,
          attachments: [
            for (final a in attachments)
              pb.MailAttachment(path: a.path, name: a.name, mime: a.mime, size: Int64(a.size)),
          ],
        ),
      ),
      (r) => r.mailSend,
    );
    return _messageFromPb(res.message);
  }

  Future<void> archive({int mailboxId = 0, required List<int> messageIds, bool archive = true}) async {
    if (messageIds.isEmpty) return;
    await conn.rpc(
      WsReq(mailArchive: pb.ReqMailArchive(mailboxId: Int64(mailboxId), messageIds: messageIds.map(Int64.new), archive: archive)),
      (r) => r.mailArchive,
    );
  }

  Future<List<models.MailingListGroup>> groupList({int mailboxId = 0}) async {
    final res = await conn.rpc(WsReq(mailGroupList: pb.ReqMailGroupList(mailboxId: Int64(mailboxId))), (r) => r.mailGroupList);
    return res.groups
        .map((g) => models.MailingListGroup(id: g.groupId, name: g.name, description: g.description, emails: g.emails.toList()))
        .toList();
  }

  Future<models.MailingListGroup> groupUpsert({int mailboxId = 0, required models.MailingListGroup group}) async {
    final res = await conn.rpc(
      WsReq(
        mailGroupUpsert: pb.ReqMailGroupUpsert(
          mailboxId: Int64(mailboxId),
          group: pb.MailGroup(groupId: group.id, name: group.name, description: group.description, emails: group.emails),
        ),
      ),
      (r) => r.mailGroupUpsert,
    );
    final g = res.group;
    return models.MailingListGroup(id: g.groupId, name: g.name, description: g.description, emails: g.emails.toList());
  }

  Future<bool> groupDelete({int mailboxId = 0, required String groupId}) async {
    final res = await conn.rpc(WsReq(mailGroupDelete: pb.ReqMailGroupDelete(mailboxId: Int64(mailboxId), groupId: groupId)), (r) => r.mailGroupDelete);
    return res.success;
  }

  Future<models.MailBroadcastResult> broadcast({
    int mailboxId = 0,
    String groupId = '',
    List<String> customEmails = const [],
    required String subject,
    required String bodyText,
    String bodyHtml = '',
    List<models.MailAttachment> attachments = const [],
  }) async {
    final res = await conn.rpc(
      WsReq(
        mailBroadcast: pb.ReqMailBroadcast(
          mailboxId: Int64(mailboxId),
          groupId: groupId,
          customEmails: customEmails,
          subject: subject,
          bodyText: bodyText,
          bodyHtml: bodyHtml,
          attachments: [
            for (final a in attachments)
              pb.MailAttachment(path: a.path, name: a.name, mime: a.mime, size: Int64(a.size)),
          ],
        ),
      ),
      (r) => r.mailBroadcast,
    );
    return models.MailBroadcastResult(
      sentCount: res.queuedCount,
      failures: res.failures.map((f) => models.MailBroadcastFailure(toAddr: f.toAddr, error: f.error)).toList(),
    );
  }

  models.MailDomain _domainFromPb(pb.MailDomain d) => models.MailDomain(
        domain: d.hostname,
        zoneId: d.zoneId,
        sendingEnabled: d.sendingEnabled,
        routingEnabled: d.routingEnabled,
        createdAt: d.createdTsMs.toInt(),
        setupSteps: d.setupSteps.map((s) => models.MailDomainSetupStep(key: s.key, status: s.status, detail: s.detail)).toList(),
        errorSummary: d.errorSummary,
      );

  models.MailMailbox _mailboxFromPb(pb.MailMailbox m) => models.MailMailbox(
        mailboxId: m.mailboxId.toInt(),
        address: m.address,
        kind: _kindFromPb(m.kind),
        siteId: m.siteIid.toInt(),
        siteName: m.siteName,
        label: m.label,
        subscriberLimit: m.subscriberLimit,
        myAccess: _accessFromPb(m.myAccess),
        unreadCount: m.unreadCount,
        members: m.members.map(_memberFromPb).toList(),
      );

  models.MailMailboxMember _memberFromPb(pb.MailMailboxMember m) =>
      models.MailMailboxMember(uid: m.memberIid.toInt(), name: m.name, email: m.email, access: _accessFromPb(m.access));

  models.MailMessage _messageFromPb(pb.MailMessage m) => models.MailMessage(
        messageId: m.messageId.toInt(),
        direction: m.direction == pb.MailDirection.MAIL_DIRECTION_IN ? models.MailDirection.inbound : models.MailDirection.outbound,
        fromAddr: m.fromAddr,
        toAddr: m.toAddr,
        subject: m.subject,
        bodyText: m.bodyText,
        bodyHtml: m.bodyHtml,
        status: _statusFromPb(m.status),
        error: m.error,
        createdAt: m.createdTsMs.toInt(),
        sentAt: m.sentTsMs.toInt(),
        isArchived: m.isArchived,
        isRead: m.isRead,
        attachments: models.MailAttachment.parseList(m.attachmentsJson),
      );

  models.MailStatus _statusFromPb(pb.MailStatus s) => switch (s) {
        pb.MailStatus.MAIL_STATUS_RECEIVED => models.MailStatus.received,
        pb.MailStatus.MAIL_STATUS_QUEUED => models.MailStatus.queued,
        pb.MailStatus.MAIL_STATUS_SENT => models.MailStatus.sent,
        pb.MailStatus.MAIL_STATUS_FAILED => models.MailStatus.failed,
        _ => models.MailStatus.unknown,
      };

  models.MailMailboxKind _kindFromPb(pb.MailMailboxKind k) => switch (k) {
        pb.MailMailboxKind.MAIL_MAILBOX_KIND_PERSONAL => models.MailMailboxKind.personal,
        pb.MailMailboxKind.MAIL_MAILBOX_KIND_SITE => models.MailMailboxKind.site,
        _ => models.MailMailboxKind.unspecified,
      };

  models.MailMailboxAccess _accessFromPb(pb.MailMailboxAccess a) => switch (a) {
        pb.MailMailboxAccess.MAIL_MAILBOX_ACCESS_READ => models.MailMailboxAccess.read,
        pb.MailMailboxAccess.MAIL_MAILBOX_ACCESS_WRITE => models.MailMailboxAccess.write,
        _ => models.MailMailboxAccess.unspecified,
      };
}
