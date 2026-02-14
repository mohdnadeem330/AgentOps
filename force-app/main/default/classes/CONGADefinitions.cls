public virtual class CONGADefinitions{
    public static final Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    
    public static final map<string, CONGA_Settings__mdt> mpCONGAsettings = CONGA_Settings__mdt.getAll();
    
    public static final string orgName = isSandbox ? 'SANDBOX' : 'PRODUCTION';
    
    public static final String CONGA_API_URL = mpCONGAsettings.get(orgName).CONGA_API_URL__c; 
    //'https://coreapps-preview.congacloud.eu/api/ingress/v1/Merge';
    
    public static final String MERGE_URL = mpCONGAsettings.get(orgName).CONGA_MERGE_URL__c; 
    //'https://coreapps-preview.congacloud.eu/api/ingress/v1/Merge/'; 
    
    public static final String INSTANCE_URL = URL.getOrgDomainURL().toExternalForm(); 
    //'https://aldarproperties--congadev.sandbox.my.salesforce.com'; 
    
    public static final String ORG_ID = UserInfo.getOrganizationId();
    
    public static final String STATUS_URL_BASE = mpCONGAsettings.get(orgName).CONGA_STATUS_URL__c; 
    //'https://coreapps-preview.congacloud.eu/api/ingress/v1/status/';
    
    public static final String BASE_DOWNLOAD_URL = mpCONGAsettings.get(orgName).BASE_DOWNLOAD_URL__c; 
    //'https://coreapps-preview.congacloud.eu/api/presigned/v1/PreSignedService/';
    
    public static final String BASE_DOWNLOAD_DOCUMENTFINAL = mpCONGAsettings.get(orgName).BASE_DOWNLOAD_DOC_URL__c; 
    //'https://coreapps-preview.congacloud.eu/api/presigned/v1/PreSignedService/';
    
    public static final String CONGA_AUTH_URL = mpCONGAsettings.get(orgName).CONGA_AUTH_URL__c; 
    //'https://login-preview.congacloud.eu/api/v1/auth/connect/token';
    
    public static final String CLIENT_ID = mpCONGAsettings.get(orgName).CONGA_CLIENT_ID__c; 
    //'b79c5a44-7c19-453e-b1b1-eb18d9536b0b';
    
    public static final String CLIENT_SECRET = mpCONGAsettings.get(orgName).CONGA_CLIENT_SECRET__c; 
    //'v6y!$j!k7OV89b!$f9-t!jy3O';
    
    public static final String GRANT_TYPE = mpCONGAsettings.get(orgName).CONGA_GRANT_TYPE__c; 
    //'client_credentials';
    
    public static final String SF_AUTH_URL = mpCONGAsettings.get(orgName).SF_AUTH_URL__c; 
    //'https://aldarproperties--congadev.sandbox.my.salesforce.com/services/oauth2/token';
    
    public static final String SF_CLIENT_ID = mpCONGAsettings.get(orgName).SF_CLIENT_ID__c; 
    //'3MVG9Bzfq5n2Kba5mkELwP9FIxHuFt8CwRVGmJJFO09N2OvHlId8_7DQJeSChoO7UokAwHWyh5q_KGI348LBV';
    
    public static final String SF_CLIENT_SECRET = mpCONGAsettings.get(orgName).SF_CLIENT_SECRET__c; 
    //'1E16C1B8DEE701C78F34744689E1891F488DEDD5D07FA1D8DB0FD178236F9594';
    
    public static final String SF_USERNAME = mpCONGAsettings.get(orgName).SF_USERNAME__c; 
    //'arv2024!@aldar.com.congadev';
    
    public static final String SF_PASSWORD = mpCONGAsettings.get(orgName).SF_PASSWORD__c; 
    //'Ak@Feb@123';
}