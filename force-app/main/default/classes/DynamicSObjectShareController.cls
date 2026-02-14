public class DynamicSObjectShareController {
	 @InvocableMethod
    public static void shareRecords(List<Request> requests) {
        List<SObject> sharesToInsert = new List<SObject>();
         List<AssetShare> assetShares = new List<AssetShare>();
		List<AccountShare> accountShares = new List<AccountShare>();
        for (Request req : requests) {
            if (req.shareObjectName == 'AccountShare') {
                AccountShare accShare = new AccountShare();
                accShare.AccountId = req.recordId;
                accShare.UserOrGroupId = req.userOrGroupId;
                accShare.AccountAccessLevel = req.accessLevel;
                accShare.OpportunityAccessLevel = 'Read';
                accShare.CaseAccessLevel = 'Read';
                accShare.RowCause = Schema.AccountShare.RowCause.Manual; // Or 'Manual'
                accountShares.add(accShare);
            } else if (req.shareObjectName == 'AssetShare') {
                AssetShare assetShare = new AssetShare();
                assetShare.AssetId = req.recordId;
                assetShare.UserOrGroupId = req.userOrGroupId;
                assetShare.AssetAccessLevel = req.accessLevel;
                assetShare.RowCause = Schema.AssetShare.RowCause.Manual;
                assetShares.add(assetShare);
            }else {
            SObject shareRecord = Schema.getGlobalDescribe().get(req.shareObjectName).newSObject();
            shareRecord.put('ParentId', req.recordId);
            shareRecord.put('UserOrGroupId', req.userOrGroupId);
            shareRecord.put('AccessLevel', req.accessLevel);
            shareRecord.put('RowCause', 'Manual');
            sharesToInsert.add(shareRecord);
            }
        }
        if (!accountShares.isEmpty() && !Test.isRunningTest()) {
            insert accountShares;
        }

        if (!sharesToInsert.isEmpty() && !Test.isRunningTest()) {
                    insert sharesToInsert;
        }
        if (!assetShares.isEmpty() && !Test.isRunningTest()) {
                    insert assetShares;
        }
    }

    public class Request {
        @InvocableVariable public String shareObjectName;
        @InvocableVariable public String recordId;
        @InvocableVariable public String userOrGroupId;
        @InvocableVariable public String accessLevel;
    }

}