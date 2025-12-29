function markArchivedAsRead() {
  var threads = GmailApp.search('label:unread -label:inbox');
  GmailApp.markThreadsRead(threads);
};
