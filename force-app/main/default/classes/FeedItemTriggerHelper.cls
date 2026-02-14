/*
*********************************************************
Apex Class Name    : FeedItemTriggerHelper
Created Date       : 2025-08-13
@description       : This Class is used for FeedItemTriggerHandler Common Logic
@author            : Daksh Sharma
Modification Log:
Ver   Date         Author                Modification
1.0   2025-08-13   Daksh Sharma          Initial Version
*********************************************************
*/
public class FeedItemTriggerHelper {

    public static void createCaseComment(List<FeedItem> newFeedItems) {
        Set<Id> caseIds = new Set<Id>();
        Map<Id, FeedItem> caseFeedItems = new Map<Id, FeedItem>();

        // Step 1: Filter feed items where parent is Case and FeedType is 'TextPost'
        for (FeedItem fi : newFeedItems) {
            if (fi.ParentId != null && String.valueOf(fi.ParentId).startsWith('500') && fi.Type == 'TextPost') {
                caseIds.add(fi.ParentId);
                caseFeedItems.put(fi.ParentId, fi);
            }
        }

        if (caseIds.isEmpty()) return;

        // Step 2: Query Cases and collect OwnerIds
        Map<Id, Case> caseMap = new Map<Id, Case>([
            SELECT Id, OwnerId
            FROM Case
            WHERE Id IN :caseIds
        ]);

        Set<Id> ownerIds = new Set<Id>();
        for (Case c : caseMap.values()) {
            if (c.OwnerId != null) {
                ownerIds.add(c.OwnerId);
            }
        }

        // Step 3: Query Group (Queue) info
        Map<Id, Group> queueMap = new Map<Id, Group>([
            SELECT Id, DeveloperName
            FROM Group
            WHERE Id IN :ownerIds AND DeveloperName = 'North_Baniyas_Queue'
        ]);

        // Step 4: Build comments
        List<CaseComment> commentsToInsert = new List<CaseComment>();

        for (Id caseId : caseMap.keySet()) {
            Case c = caseMap.get(caseId);

            if (queueMap.containsKey(c.OwnerId)) {
                FeedItem fi = caseFeedItems.get(caseId);

                String cleanBody = removeHtmlTags(fi.Body);

                CaseComment comment = new CaseComment(
                    ParentId = caseId,
                    CommentBody = cleanBody,
                    IsPublished = true
                );

                commentsToInsert.add(comment);
            }
        }

        // Step 5: Insert CaseComments
        if (!commentsToInsert.isEmpty()) {
            insert commentsToInsert;
        }
    }

    // Utility method to remove HTML Tags
    private static String removeHtmlTags(String htmlText) {
        if (String.isBlank(htmlText)) return '';
        return htmlText.replaceAll('<[^>]*>', '');
    }
}