public with sharing class ECSS_AssetFileGenerator {

    public class OutputWrapper {
        @InvocableVariable(label='ContentVersion Id')
        public Id contentVersionId;
    }

    @InvocableMethod(label='Generate Asset CSV File as ContentVersion')
    public static List<OutputWrapper> generate(List<List<Id>> assetIdWrapper) {
        List<Id> assetIds = assetIdWrapper[0];

        List<Asset> assets = [
            SELECT Name, ExternalIdentifier, ECSS_Unit_Type__c, ECSS_Floor_Number__c, 
                   ECSS_Unit_Area__c, ECSS_Number_of_Bedrooms__c, ECSS_Number_of_Baths__c,
                   ECSS_View__c, ECSS_Project__r.Name, ECSS_Zone__r.Name, 
                   ECSS_Building_Section__r.Name, ECSS_Unit_Usage__c,Account.Name
            FROM Asset
            WHERE Id IN :assetIds
        ];

        String csv = 'Unit Name,Account Name,External ID,Unit Type,Floor,Area,Beds,Baths,View,Project,Zone,Building,Unit Usage\n';
        for (Asset a : assets) {
            csv += '"' + a.Name + '",'
                 + '"' + (a.Account != null ? a.Account.Name : '')+ '",'
                + '"' + a.ExternalIdentifier + '",'
                + '"' + a.ECSS_Unit_Type__c + '",'
                + '"' + a.ECSS_Floor_Number__c + '",'
                + '"' + a.ECSS_Unit_Area__c + '",'
                + '"' + a.ECSS_Number_of_Bedrooms__c + '",'
                + '"' + a.ECSS_Number_of_Baths__c + '",'
                + '"' + a.ECSS_View__c + '",'
                + '"' + (a.ECSS_Project__r != null ? a.ECSS_Project__r.Name : '') + '",'
                + '"' + (a.ECSS_Zone__r != null ? a.ECSS_Zone__r.Name : '') + '",'
                + '"' + (a.ECSS_Building_Section__r != null ? a.ECSS_Building_Section__r.Name : '') + '",'
                + '"' + a.ECSS_Unit_Usage__c + '"\n';
        }

        ContentVersion cv = new ContentVersion();
        cv.Title = 'Asset_Report';
        cv.PathOnClient = 'Asset_Report.csv';
        cv.VersionData = Blob.valueOf(csv);
        insert cv;

        OutputWrapper result = new OutputWrapper();
        result.contentVersionId = cv.Id;

        return new List<OutputWrapper>{ result };
    }
}