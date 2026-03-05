function markArchivedAsRead() {
  var threads = GmailApp.search('label:unread -label:inbox');

  // markThreadsRead has a limit of 100 threads per call
  for (var i = 0; i < threads.length; i += 100) {
    GmailApp.markThreadsRead(threads.slice(i, i + 100));
  }
};
