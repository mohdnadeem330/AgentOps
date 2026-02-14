public with sharing class ALD_AccountController {
    
    public static String VALID_FOR = 'Valid For';
    public static String EXPIRED_BEFORE = 'Expired Before';
    
    @AuraEnabled(cacheable=true) 
    public static List<WrapperData> accountKYCExpiryCheck(String recordId){
        List<WrapperData> wrapperDataList = new List<WrapperData>();
        try {
            Map<String, String> docNameStatusClr = new Map<String, String>();
            Account acc = [SELECT Id, PassportExpiryDate__pc, Risk_Score__c, NPS__c, CSAT__c, NationalIdExpiryDate__pc, ALDnT_Sub_Legal_Reason__c, Blacklisted__c, BlacklistReason__c,IsVIP__c,CMAccountManager__r.Name,CustomerType__c 
                           FROM Account 
                           WHERE Id=:recordId];
            Integer numberDaysBetween = 0 ;
            Date todayDate = System.today();
            
            if(acc.CustomerType__c == 'VIP') {
                WrapperData wrap3 = new WrapperData();
                wrap3.key = 'Customer Type';
                wrap3.iconName ='utility:success';
                wrap3.variant = 'success';
                wrap3.alternativeText = '<span style="color: red"> Select </span>Customer '; 
                wrapperDataList.add(wrap3);
            }
            
            WrapperData wrap5 = new WrapperData();
            wrap5.key = 'Risk Score';
            if (acc.Risk_Score__c != null) {
                Decimal roundedRiskScore = acc.Risk_Score__c.setScale(2, RoundingMode.HALF_UP);
                wrap5.iconName = roundedRiskScore >= 3.01  ? 'utility:success' : roundedRiskScore >= 2.01 && roundedRiskScore <= 3.00 ? 'utility:warning' : 'utility:error';
                wrap5.variant = roundedRiskScore >= 3.01  ? 'success' : roundedRiskScore >= 2.01 && roundedRiskScore <= 3.00 ? 'warning' : 'error';
                wrap5.alternativeText = String.valueOf(roundedRiskScore);
            } else {
                wrap5.iconName = 'utility:error'; 
                wrap5.variant = 'error';          
                wrap5.alternativeText = 'N/A';
            }
            System.debug('wrap5: ' + wrap5);
            wrapperDataList.add(wrap5);
            
            if(acc.CustomerType__c == 'VIP') {
                WrapperData wrap4 = new WrapperData();
                wrap4.key = 'CM Manager';
                wrap4.iconName = 'utility:success';
                wrap4.variant = 'success';
                wrap4.alternativeText = acc.CMAccountManager__r.Name != null? String.valueOf(acc.CMAccountManager__r.Name) : 'N/A';
                wrapperDataList.add(wrap4);
            }
            
            WrapperData wrap2 = new WrapperData();
            wrap2.key = 'CSAT Score';
            wrap2.iconName = acc.CSAT__c > 7  ? 'utility:success' : 'utility:error';
            wrap2.variant = acc.CSAT__c > 7  ? 'success' : 'error';
            wrap2.alternativeText = acc.CSAT__c != null? String.valueOf(acc.CSAT__c) : 'No Rating';
            wrapperDataList.add(wrap2);          
            
            if(acc.NationalIdExpiryDate__pc != null) {
                numberDaysBetween = todayDate.daysBetween(acc.NationalIdExpiryDate__pc);
            }
            wrapperDataList.add(new WrapperData('National Id', numberDaysBetween, acc.NationalIdExpiryDate__pc != null ? null : 'N/A'));
            
            WrapperData wrap1 = new WrapperData();
            wrap1.key = 'NPS Score';
            wrap1.iconName = acc.NPS__c > 7 ? 'utility:success' : 'utility:error';
            wrap1.variant = acc.NPS__c > 7 ? 'success' : 'error';
            wrap1.alternativeText = acc.NPS__c != null? String.valueOf(acc.NPS__c) : 'No Rating';
            wrapperDataList.add(wrap1);
            
            WrapperData wrap = new WrapperData();
            wrap.key = 'Customer Flag';
            wrap.iconName = acc.Blacklisted__c ? 'utility:error' : 'utility:success';
            wrap.variant = acc.Blacklisted__c ? 'error' : 'success';
            wrap.alternativeText = acc.Blacklisted__c ? acc.BlacklistReason__c : 'Valid';         
            if(wrap.variant == 'error' && acc.ALDnT_Sub_Legal_Reason__c == 'Court Order') {
                List<HexaBPM__Service_Request__c> srList = [SELECT Id,SRType__c, Name FROM HexaBPM__Service_Request__c WHERE SRType__c = 'Legal-Court Order' AND HexaBPM__IsClosedStatus__c = false ORDER BY CreatedDate DESC LIMIT 1];
                if(!srList.isEmpty()) {
                    wrap.alternativeText = srList[0].SRType__c+' <a href="/' + srList[0].Id + '"> ' + srList[0].Name + '</a>';
                }
            }
            wrapperDataList.add(wrap);
            
            if(acc.PassportExpiryDate__pc != null) {
                numberDaysBetween = todayDate.daysBetween(acc.PassportExpiryDate__pc);
            }
            wrapperDataList.add(new WrapperData('Passport', numberDaysBetween, acc.PassportExpiryDate__pc != null ? null : 'N/A'));
            
            return wrapperDataList;            
        } catch (Exception e) {
            LoggerService.save(LoggerService.addApexLog(e,'ALD_AccountController','accountKYCExpiryCheck',''));
            return null;
        }
    }
    
    public class WrapperData {
        @AuraEnabled
        public String key;
        @AuraEnabled
        public String iconName;
        @AuraEnabled
        public String alternativeText;
        @AuraEnabled
        public String variant;
        
        public WrapperData(String key, Integer numberDaysBetween, String altText){
            this.key = key;
            this.iconName = altText == 'N/A' ? 'utility:error' : numberDaysBetween <= 90 ? 'utility:warning' : numberDaysBetween > 90 ? 'utility:success' : numberDaysBetween < 30 ? 'utility:error' : 'utility:success';
            this.alternativeText = altText == 'N/A' ? altText : numberDaysBetween > 0 ? ('Expire in ' + numberDaysBetween + ' days') : ('Expired ' + numberDaysBetween + ' days before');
                this.variant = altText == 'N/A' ? 'error' : numberDaysBetween <= 90 ? 'warning' : numberDaysBetween > 90 ? 'success' : numberDaysBetween < 30 ? 'error' : 'success';
        }
        
        public WrapperData(){}
    }
}