public with sharing class MobileConfigurationsUtility {
	
	public static MobileAppConfiguration__mdt getMobileConfiguration(String configurationName) {

		MobileAppConfiguration__mdt configuration = [SELECT Id, DeveloperName , MinimumAllowedBuildNumber__c, LatestBuildNumber__c, LatestAppVersion__c, MinimumAllowedAppVersion__c, UpdateURL__c, AppIdentifier__c FROM MobileAppConfiguration__mdt WHERE DeveloperName	 =: configurationName];
		return configuration;
	}

	//Returns true if the the current version and build are the latest or more than the latest. Otherwise, returns false./
	public static Boolean isOnLatestVersion(String currentVersion, String currentBuildNumber, MobileAppConfiguration__mdt config) {

		Boolean isOnLatest = true;
		
		Decimal currentVersionDec = currentVersion == null ? 0 : Decimal.valueOf(currentVersion);
		Decimal currentBuildDec = currentBuildNumber == null ? 0 : Decimal.valueOf(currentBuildNumber);

		Decimal latestVersion = config.LatestAppVersion__c == null ? 0 : config.LatestAppVersion__c;
		Decimal latestBuild = config.LatestBuildNumber__c == null ? 0 : config.LatestBuildNumber__c;

		if (latestVersion == currentVersionDec) {

			if (latestBuild <= currentBuildDec)
				return true;
			else
				return false;
		}
		else if (latestVersion < currentVersionDec)
			return true;
		else
			return false;
	}

	public static Boolean isAppVersionAllowed(String appVersion, String buildNumber,String configurationName) {
		
		Boolean isOldVersionAllowed = true;
		
		if (appVersion != null) {
							
			MobileAppConfiguration__mdt config = getMobileConfiguration(configurationName);
			isOldVersionAllowed = isVersionAllowed(appVersion, buildNumber, config);
		}
		
		return isOldVersionAllowed;
	}
	  
	private static Boolean isVersionAllowed(String currentVersion, String currentBuildNumber, MobileAppConfiguration__mdt config) {
		
		Boolean isVersionAllowed = true;
		
		Decimal currentVersionDec = currentVersion == null ? 0 : Decimal.valueOf(currentVersion);
		Decimal currentBuildDec = currentBuildNumber == null ? 0 : Decimal.valueOf(currentBuildNumber);

		Decimal minimumVersion = config.MinimumAllowedAppVersion__c == null ? 0 : config.MinimumAllowedAppVersion__c;
		Decimal minimumBuild = config.MinimumAllowedBuildNumber__c == null ? 0 : config.MinimumAllowedBuildNumber__c;

		if (currentVersionDec < minimumVersion) {
			isVersionAllowed = false;
		}
		else if (currentVersionDec == minimumVersion) {
			isVersionAllowed = currentBuildDec >= minimumBuild;
		}
		else {
			isVersionAllowed = true;
		}

		return isVersionAllowed;
	}

	public static MobileVersionModel evaluateVersionForLatest(String currentVersion, String currentBuildNumber, String configurationName) {
    	
    	MobileAppConfiguration__mdt config = getMobileConfiguration(configurationName);
		//Boolean isLatest = true;//isOnLatestVersion(currentVersion, currentBuildNumber, config) || currentVersion == '1.4';
		Boolean isLatest = isOnLatestVersion(currentVersion, currentBuildNumber, config);

		return new MobileVersionModel(config, isLatest);
	}

	public static MobileVersionModel evaluateVersionForAllowed(String currentVersion, String currentBuildNumber, String configurationName) {
    	
    	MobileAppConfiguration__mdt config = getMobileConfiguration(configurationName);
    	//Boolean isAllowed = true;//isVersionAllowed(currentVersion, currentBuildNumber, config) || currentVersion == '1.4';
    	Boolean isAllowed = isVersionAllowed(currentVersion, currentBuildNumber, config);

		return new MobileVersionModel(config, isAllowed);
	}

	public class MobileVersionModel {

    	public String appVersion {get;set;}
    	public String buildNumber {get;set;}
        public String appUpdateUrl {get; set;}
    	public Boolean isLatest {get; set;}
        public String message {get; set;}
        public String title {get; set;}

    	public MobileVersionModel (MobileAppConfiguration__mdt config, Boolean isSatisfied) {

    		this.appVersion = String.valueOf(config.LatestAppVersion__c);
    		this.buildNumber = String.valueOf(config.LatestBuildNumber__c);
    		this.isLatest = isSatisfied;
            this.appUpdateUrl = config.UpdateURL__c == null? '' : config.UpdateURL__c;

            String message = 'There is a newer version ' + this.appVersion + ' (' + this.buildNumber +  ') available. Do you want to update it now to enjoy stability and latest features?';
            this.message = this.isLatest ? 'Success' : message;
            this.title = this.isLatest ? 'You are on the latest version!' : 'New Version Available!';
    	}
    }
}