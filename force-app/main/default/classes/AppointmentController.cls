/**********************************************************************************************************************
* Name               : AppointmentController                                                        
* Description        : Class to make callout to appointment system.
* Usage              : Appointment LWC (Used on platform and portal)                                                     
* Created By         : PWC Digital Middle East
* Last Modified By   : tdontha@aldar.com
* --------------------------------------------------------------------------------------------------------------------
* Version       Author                  Date            Comment                                                                       
* 1.0           paras.bhatt@pwc.com     06/06/2022      Initial Draft       
* 2.0           Saran                   26/11/2022      Implemented Appointment Cancellation Solution and Updated Create Appointment
* 3.0           Tharun                  13/06/2024      Event Appointments & adding salesAgent for direct appointments BPM-346
******************************************************************************************************************/

public with sharing class AppointmentController {
    //static map<string,string> contryTOISO2Code = new map<string,string>{'afghanistan' => 'AF' , 'albania' => 'AL' , 'algeria' => 'DZ' , 'american samoa' => 'AS' , 'andorra' => 'AD' , 'angola' => 'AO' , 'anguilla' => 'AI' , 'antarctica' => 'AQ' , 'antigua and barbuda' => 'AG' , 'argentina' => 'AR' , 'armenia' => 'AM' , 'aruba' => 'AW' , 'australia' => 'AU' , 'austria' => 'AT' , 'azerbaijan' => 'AZ' , 'bahamas' => 'BS' , 'bahrain' => 'BH' , 'bangladesh' => 'BD' , 'barbados' => 'BB' , 'belarus' => 'BY' , 'belgium' => 'BE' , 'belize' => 'BZ' , 'benin' => 'BJ' , 'bermuda' => 'BM' , 'bhutan' => 'BT' , 'bolivia' => 'BO' , 'bosnia and herzegovina' => 'BA' , 'botswana' => 'BW' , 'bouvet island' => 'BV' , 'brazil' => 'BR' , 'british indian ocean territory' => 'IO' , 'brunei' => 'BN' , 'bulgaria' => 'BG' , 'burkina faso' => 'BF' , 'burundi' => 'BI' , 'cape verde' => 'CV' , 'cambodia' => 'KH' , 'cameroon' => 'CM' , 'canada' => 'CA' , 'cayman islands' => 'KY' , 'central african republic' => 'CF' , 'chad' => 'TD' , 'chile' => 'CL' , 'china' => 'CN' , 'christmas island' => 'CX' , 'cocos [keeling] islands' => 'CC' , 'colombia' => 'CO' , 'comoros' => 'KM' , 'congo [drc]' => 'CD' , 'congo [republic]' => 'CG' , 'cook islands' => 'CK' , 'costa rica' => 'CR' , 'croatia' => 'HR' , 'cuba' => 'CU' , 'cyprus' => 'CY' , 'czech republic' => 'CZ' , 'côte d\'ivoire' => 'CI' , 'denmark' => 'DK' , 'djibouti' => 'DJ' , 'dominica' => 'DM' , 'dominican republic' => 'DO' , 'ecuador' => 'EC' , 'egypt' => 'EG' , 'el salvador' => 'SV' , 'equatorial guinea' => 'GQ' , 'eritrea' => 'ER' , 'estonia' => 'EE' , 'swaziland' => 'SZ' , 'ethiopia' => 'ET' , 'falkland islands [islas malvinas]' => 'FK' , 'faroe islands' => 'FO' , 'fiji' => 'FJ' , 'finland' => 'FI' , 'france' => 'FR' , 'french guiana' => 'GF' , 'french polynesia' => 'PF' , 'french southern territories' => 'TF' , 'gabon' => 'GA' , 'gambia' => 'GM' , 'georgia' => 'GE' , 'germany' => 'DE' , 'ghana' => 'GH' , 'gibraltar' => 'GI' , 'greece' => 'GR' , 'greenland' => 'GL' , 'grenada' => 'GD' , 'guadeloupe' => 'GP' , 'guam' => 'GU' , 'guatemala' => 'GT' , 'guernsey' => 'GG' , 'guinea' => 'GN' , 'guinea-bissau' => 'GW' , 'guyana' => 'GY' , 'haiti' => 'HT' , 'heard island and mcdonald islands' => 'HM' , 'vatican city' => 'VA' , 'honduras' => 'HN' , 'hong kong' => 'HK' , 'hungary' => 'HU' , 'iceland' => 'IS' , 'india' => 'IN' , 'indonesia' => 'ID' , 'iran' => 'IR' , 'iraq' => 'IQ' , 'ireland' => 'IE' , 'isle of man' => 'IM' , 'israel' => 'IL' , 'italy' => 'IT' , 'jamaica' => 'JM' , 'japan' => 'JP' , 'jersey' => 'JE' , 'jordan' => 'JO' , 'kazakhstan' => 'KZ' , 'kenya' => 'KE' , 'kiribati' => 'KI' , 'north korea' => 'KP' , 'south korea' => 'KR' , 'kuwait' => 'KW' , 'kyrgyzstan' => 'KG' , 'laos' => 'LA' , 'latvia' => 'LV' , 'lebanon' => 'LB' , 'lesotho' => 'LS' , 'liberia' => 'LR' , 'libya' => 'LY' , 'liechtenstein' => 'LI' , 'lithuania' => 'LT' , 'luxembourg' => 'LU' , 'macau' => 'MO' , 'madagascar' => 'MG' , 'malawi' => 'MW' , 'malaysia' => 'MY' , 'maldives' => 'MV' , 'mali' => 'ML' , 'malta' => 'MT' , 'marshall islands' => 'MH' , 'martinique' => 'MQ' , 'mauritania' => 'MR' , 'mauritius' => 'MU' , 'mayotte' => 'YT' , 'mexico' => 'MX' , 'micronesia' => 'FM' , 'moldova' => 'MD' , 'monaco' => 'MC' , 'mongolia' => 'MN' , 'montenegro' => 'ME' , 'montserrat' => 'MS' , 'morocco' => 'MA' , 'mozambique' => 'MZ' , 'myanmar [burma]' => 'MM' , 'namibia' => 'NA' , 'nauru' => 'NR' , 'nepal' => 'NP' , 'netherlands antilles' => 'AN' , 'netherlands' => 'NL' , 'new caledonia' => 'NC' , 'new zealand' => 'NZ' , 'nicaragua' => 'NI' , 'niger' => 'NE' , 'nigeria' => 'NG' , 'niue' => 'NU' , 'norfolk island' => 'NF' , 'northern mariana islands' => 'MP' , 'norway' => 'NO' , 'oman' => 'OM' , 'pakistan' => 'PK' , 'palau' => 'PW' , 'palestinian territories' => 'PS' , 'gaza strip' => 'PS' , 'panama' => 'PA' , 'papua new guinea' => 'PG' , 'paraguay' => 'PY' , 'peru' => 'PE' , 'philippines' => 'PH' , 'pitcairn islands' => 'PN' , 'poland' => 'PL' , 'portugal' => 'PT' , 'puerto rico' => 'PR' , 'qatar' => 'QA' , 'macedonia [fyrom]' => 'MK' , 'romania' => 'RO' , 'russia' => 'RU' , 'rwanda' => 'RW' , 'réunion' => 'RE' , 'saint helena' => 'SH' , 'saint kitts and nevis' => 'KN' , 'saint lucia' => 'LC' , 'saint pierre and miquelon' => 'PM' , 'saint vincent and the grenadines' => 'VC' , 'samoa' => 'WS' , 'san marino' => 'SM' , 'são tomé and príncipe' => 'ST' , 'saudi arabia' => 'SA' , 'senegal' => 'SN' , 'serbia' => 'RS' , 'seychelles' => 'SC' , 'sierra leone' => 'SL' , 'singapore' => 'SG' , 'slovakia' => 'SK' , 'slovenia' => 'SI' , 'solomon islands' => 'SB' , 'somalia' => 'SO' , 'south africa' => 'ZA' , 'south georgia and the south sandwich islands' => 'GS' , 'spain' => 'ES' , 'sri lanka' => 'LK' , 'sudan' => 'SD' , 'suriname' => 'SR' , 'svalbard and jan mayen' => 'SJ' , 'sweden' => 'SE' , 'switzerland' => 'CH' , 'syria' => 'SY' , 'taiwan' => 'TW' , 'tajikistan' => 'TJ' , 'tanzania' => 'TZ' , 'thailand' => 'TH' , 'timor-leste' => 'TL' , 'togo' => 'TG' , 'tokelau' => 'TK' , 'tonga' => 'TO' , 'trinidad and tobago' => 'TT' , 'tunisia' => 'TN' , 'turkey' => 'TR' , 'turkmenistan' => 'TM' , 'turks and caicos islands' => 'TC' , 'tuvalu' => 'TV' , 'uganda' => 'UG' , 'ukraine' => 'UA' , 'united arab emirates' => 'AE' , 'united kingdom' => 'GB' , 'u.s. minor outlying islands' => 'UM' , 'united states' => 'US' , 'uruguay' => 'UY' , 'uzbekistan' => 'UZ' , 'vanuatu' => 'VU' , 'venezuela' => 'VE' , 'vietnam' => 'VN' , 'british virgin islands' => 'VG' , 'u.s. virgin islands' => 'VI' , 'wallis and futuna' => 'WF' , 'western sahara' => 'EH' , 'yemen' => 'YE' , 'zambia' => 'ZM' , 'zimbabwe' => 'ZW' , 'kosovo' => 'XK'};
    static map<string,string> contryTOISO2Code = new map<string,string>{'afghanistan' => 'AF' , 'albania' => 'AL' , 'algeria' => 'DZ' , 'american samoa' => 'AS' , 'andorra' => 'AD' , 'angola' => 'AO' , 'anguilla' => 'AI' , 'antarctica' => 'AQ' , 'antigua and barbuda' => 'AG' , 'argentina' => 'AR' , 'armenia' => 'AM' , 'aruba' => 'AW' , 'australia' => 'AU' , 'austria' => 'AT' , 'azerbaijan' => 'AZ' , 'bahamas' => 'BS' , 'bahrain' => 'BH' , 'bangladesh' => 'BD' , 'barbados' => 'BB' , 'belarus' => 'BY' , 'belgium' => 'BE' , 'belize' => 'BZ' , 'benin' => 'BJ' , 'bermuda' => 'BM' , 'bhutan' => 'BT' , 'bolivia' => 'BO' , 'bosnia and herzegovina' => 'BA' , 'botswana' => 'BW' , 'bouvet island' => 'BV' , 'brazil' => 'BR' , 'british indian ocean territory' => 'IO' , 'brunei' => 'BN' , 'bulgaria' => 'BG' , 'burkina faso' => 'BF' , 'burundi' => 'BI' , 'cape verde' => 'CV' , 'cambodia' => 'KH' , 'cameroon' => 'CM' , 'canada' => 'CA' , 'cayman islands' => 'KY' , 'central african republic' => 'CF' , 'chad' => 'TD' , 'chile' => 'CL' , 'china' => 'CN' , 'christmas island' => 'CX' , 'cocos [keeling] islands' => 'CC' , 'colombia' => 'CO' , 'comoros' => 'KM' , 'congo [drc]' => 'CD' , 'congo [republic]' => 'CG' , 'cook islands' => 'CK' , 'costa rica' => 'CR' , 'croatia' => 'HR' , 'cuba' => 'CU' , 'cyprus' => 'CY' , 'czech republic' => 'CZ' , 'côte d\'ivoire' => 'CI' , 'denmark' => 'DK' , 'djibouti' => 'DJ' , 'dominica' => 'DM' , 'dominican republic' => 'DO' , 'ecuador' => 'EC' , 'egypt' => 'EG' , 'el salvador' => 'SV' , 'equatorial guinea' => 'GQ' , 'eritrea' => 'ER' , 'estonia' => 'EE' , 'swaziland' => 'SZ' , 'ethiopia' => 'ET' , 'falkland islands [islas malvinas]' => 'FK' , 'faroe islands' => 'FO' , 'fiji' => 'FJ' , 'finland' => 'FI' , 'france' => 'FR' , 'french guiana' => 'GF' , 'french polynesia' => 'PF' , 'french southern territories' => 'TF' , 'gabon' => 'GA' , 'gambia' => 'GM' , 'georgia' => 'GE' , 'germany' => 'DE' , 'ghana' => 'GH' , 'gibraltar' => 'GI' , 'greece' => 'GR' , 'greenland' => 'GL' , 'grenada' => 'GD' , 'guadeloupe' => 'GP' , 'guam' => 'GU' , 'guatemala' => 'GT' , 'guernsey' => 'GG' , 'guinea' => 'GN' , 'guinea-bissau' => 'GW' , 'guyana' => 'GY' , 'haiti' => 'HT' , 'heard island and mcdonald islands' => 'HM' , 'vatican city' => 'VA' , 'honduras' => 'HN' , 'hong kong' => 'HK' , 'hungary' => 'HU' , 'iceland' => 'IS' , 'india' => 'IN' , 'indonesia' => 'ID' , 'iran' => 'IR' ,'iran, islamic republic of' => 'IR' , 'iraq' => 'IQ' , 'ireland' => 'IE' , 'isle of man' => 'IM' , 'israel' => 'IL' , 'italy' => 'IT' , 'jamaica' => 'JM' , 'japan' => 'JP' , 'jersey' => 'JE' , 'jordan' => 'JO' , 'kazakhstan' => 'KZ' , 'kenya' => 'KE' , 'kiribati' => 'KI' , 'north korea' => 'KP' , 'south korea' => 'KR' , 'kuwait' => 'KW' , 'kyrgyzstan' => 'KG' , 'laos' => 'LA' , 'latvia' => 'LV' , 'lebanon' => 'LB' , 'lesotho' => 'LS' , 'liberia' => 'LR' , 'libya' => 'LY' , 'liechtenstein' => 'LI' , 'lithuania' => 'LT' , 'luxembourg' => 'LU' , 'macau' => 'MO' , 'madagascar' => 'MG' , 'malawi' => 'MW' , 'malaysia' => 'MY' , 'maldives' => 'MV' , 'mali' => 'ML' , 'malta' => 'MT' , 'marshall islands' => 'MH' , 'martinique' => 'MQ' , 'mauritania' => 'MR' , 'mauritius' => 'MU' , 'mayotte' => 'YT' , 'mexico' => 'MX' , 'micronesia' => 'FM' , 'moldova' => 'MD' , 'monaco' => 'MC' , 'mongolia' => 'MN' , 'montenegro' => 'ME' , 'montserrat' => 'MS' , 'morocco' => 'MA' , 'mozambique' => 'MZ' , 'myanmar [burma]' => 'MM' , 'namibia' => 'NA' , 'nauru' => 'NR' , 'nepal' => 'NP' , 'netherlands antilles' => 'AN' , 'netherlands' => 'NL' , 'new caledonia' => 'NC' , 'new zealand' => 'NZ' , 'nicaragua' => 'NI' , 'niger' => 'NE' , 'nigeria' => 'NG' , 'niue' => 'NU' , 'norfolk island' => 'NF' , 'northern mariana islands' => 'MP' , 'norway' => 'NO' , 'oman' => 'OM' , 'pakistan' => 'PK' , 'palau' => 'PW' , 'palestinian territories' => 'PS' ,'palestinian territory, occupied' => 'PS' , 'gaza strip' => 'PS' , 'panama' => 'PA' , 'papua new guinea' => 'PG' , 'paraguay' => 'PY' , 'peru' => 'PE' , 'philippines' => 'PH' , 'pitcairn islands' => 'PN' , 'poland' => 'PL' , 'portugal' => 'PT' , 'puerto rico' => 'PR' , 'qatar' => 'QA' , 'macedonia [fyrom]' => 'MK' , 'romania' => 'RO' , 'russia' => 'RU' , 'russian federation' => 'RU' ,'rwanda' => 'RW' , 'réunion' => 'RE' , 'saint helena' => 'SH' , 'saint kitts and nevis' => 'KN' , 'saint lucia' => 'LC' , 'saint pierre and miquelon' => 'PM' , 'saint vincent and the grenadines' => 'VC' , 'samoa' => 'WS' , 'san marino' => 'SM' , 'são tomé and príncipe' => 'ST' , 'saudi arabia' => 'SA' , 'senegal' => 'SN' , 'serbia' => 'RS' , 'seychelles' => 'SC' , 'sierra leone' => 'SL' , 'singapore' => 'SG' , 'slovakia' => 'SK' , 'slovenia' => 'SI' , 'solomon islands' => 'SB' , 'somalia' => 'SO' , 'south africa' => 'ZA' , 'south georgia and the south sandwich islands' => 'GS' , 'spain' => 'ES' , 'sri lanka' => 'LK' , 'sudan' => 'SD' , 'suriname' => 'SR' , 'svalbard and jan mayen' => 'SJ' , 'sweden' => 'SE' , 'switzerland' => 'CH' , 'syria' => 'SY' ,'syrian arab republic' => 'SY' , 'taiwan' => 'TW' , 'tajikistan' => 'TJ' , 'tanzania' => 'TZ' , 'thailand' => 'TH' , 'timor-leste' => 'TL' , 'togo' => 'TG' , 'tokelau' => 'TK' , 'tonga' => 'TO' , 'trinidad and tobago' => 'TT' , 'tunisia' => 'TN' , 'turkey' => 'TR' , 'turkmenistan' => 'TM' , 'turks and caicos islands' => 'TC' , 'tuvalu' => 'TV' , 'uganda' => 'UG' , 'ukraine' => 'UA' , 'united arab emirates' => 'AE' , 'united kingdom' => 'GB' , 'u.s. minor outlying islands' => 'UM' , 'united states' => 'US' , 'uruguay' => 'UY' , 'uzbekistan' => 'UZ' , 'vanuatu' => 'VU' , 'venezuela' => 'VE' , 'vietnam' => 'VN' , 'british virgin islands' => 'VG' , 'u.s. virgin islands' => 'VI' , 'wallis and futuna' => 'WF' , 'western sahara' => 'EH' , 'yemen' => 'YE' , 'zambia' => 'ZM' , 'zimbabwe' => 'ZW' , 'kosovo' => 'XK'};
        static map<string,string> residencyMap = new map<string,string>{'Abu Dhabi' => '1','Dubai'=>'3','Ajman'=>'2','Fujairah'=>'4','Ras Al Khaimah'=>'5','Sharjah'=>'6','Umm Al Quwain'=>'7' };
            static string BROKER = 'Broker';
    static string EMIRATI = 'Emirati';
    static string BUYER = 'Buyer';
    static string ONLINE = 'Online';
    public static Boolean IS_PASS_PARAMETER_ON_URL = false;
    public static String PARAMETER_TO_PASS = null;
    public static String BOOKED_STATUS = 'Booked';
    public static String CANCELLED_STATUS = 'Cancelled';
    public static Boolean isRunningFromBackEnd = false;
    
    /**
* getUserData
*
* This method used to return logged In user's data
* @param  none
* @return User data
*/
    @AuraEnabled(cacheable=true)
    public static User getUserData(String recordId){
        User userRecordToReturn ;
        if(recordId!='' && recordId!=''){
            //Removed SECURITY_ENFORCED as Mobile no. is not accessible
            // Updated By Moh Sarfaraj for BPE-105
            userRecordToReturn = [SELECT Id,FirstName,LastName,Email,MobilePhone,Account.AppointmentSystemID__c,
                                  ContactId,Contact.BrokerType__c,Account.Name,Account.ERPID__c,Contact.MobileCountryCode__c,
                                  Contact.MobilePhone__c,Contact.Name,Contact.AgentID__c,Contact.CountryOfResidence__c,
                                  Contact.ResidentStatus__c,Contact.MailingCountryCode,Contact.VisaUIDNo__c,Contact.NationalIdNumber__c,
                                  Contact.Account.BrokerManager__c,RoleName__c,Extension
                                  FROM User WHERE Id = :recordId LIMIT 1];
        }
        return userRecordToReturn;
    }
    
    /**
* getBuyerData
*
* This method used to return record details
*
* @param  none
* @return BuyerDetails warpper class
*/
    @AuraEnabled(cacheable=true)
    public static map<String,BuyerDetails> getBuyerData(String recordId){
        map<String,BuyerDetails> mapToReturn = new  map<String,BuyerDetails>();
        BuyerDetails recordToReturn =new BuyerDetails();
        if(recordId!='' && recordId!=''){
            String sObjectType = String.ValueOf(((ID)recordId).getSObjectType());
            if(sObjectType.equalsIgnoreCase('Lead')){
                mapToReturn.put('Lead' , new BuyerDetails([select id, FirstName,LastName,Email,MobileCountryCode__c,MobileNumber1__c,Nationality__c,ResidentStatus__c,PassportNumber__c,PassportExpiryDate__c,CustomerLocation__c,NationalId__c,NationalIdExpiryDate__c, NumberOfBedrooms__c from  Lead where id = :recordId limit 1]) );
            }else if(sObjectType.equalsIgnoreCase('Opportunity')){
                mapToReturn.put('Opportunity' , new BuyerDetails([select id,AccountId,Contact__r.Id,Contact__r.MobilePhone__c,Contact__r.MobileCountryCode__c,Contact__r.FirstName,Contact__r.LastName,Contact__r.Email,/*Contact__r.MobileCountryCode__c,Contact__r.MobileNumber1__c,*/Contact__r.Nationality__c,Contact__r.ResidentStatus__c,Contact__r.NationalIdNumber__c,Contact__r.NationalIdExpiryDate__c ,Contact__r.CustomerLocation__c,Contact__r.PassportNumber__c,Contact__r.PassportExpiryDate__c,NumberOfBedrooms__c  from  Opportunity where id = :recordId limit 1]));
            }else if(sObjectType.equalsIgnoreCase('Contact')){
                mapToReturn.put('Contact' ,new BuyerDetails([select id,AccountId,FirstName,LastName,MobilePhone__c,MobileCountryCode__c,Email,/*MobileCountryCode__c,MobileNumber1__c,*/Nationality__c,ResidentStatus__c,NationalIdNumber__c,NationalIdExpiryDate__c,CustomerLocation__c,PassportNumber__c,PassportExpiryDate__c from  Contact where id = :recordId limit 1]) );
            }
        }
        return mapToReturn;
    }
    
    /**
* getAllProjects 
*
* return available projects
* 
* @usage opportunityUnitSearch LWC
*
* @param none
* @return   list<map<String,string>>  list of select options 
*/
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAllProjects() {
        list<map<String,string>> filtersToReturn = new list<map<String,string>>();
        
        for(Project__c tempProject: [select id,Name from Project__c where AppointmentSystemID__c !=null  and IsActive__c=true] ){
            map<string,string> tempMap=new map<string,string>();
            tempMap.put('label',tempProject.Name);
            tempMap.put('value',tempProject.id);
            filtersToReturn.add(tempMap);
        }
        return filtersToReturn;
    }
    
    
    
    
    /**
* getNationalitiesPicklist
*
* This method used to return all the nationality picklist values
* @param  none
* @return select options
*/
    @AuraEnabled(cacheable=true)
    public static list<map<String,string>> getNationalitiesPicklist(){
        list<map<String,string>> picklistToReturn = new list<map<String,string>>();
        Schema.DescribeFieldResult fieldResult = Appointment__c.Nationality__c.getDescribe();
        for(Schema.PicklistEntry tempVal: fieldResult.getPicklistValues()){
            map<string,string> tempMap=new map<string,string>();
            tempMap.put('label',tempVal.getLabel());
            tempMap.put('value',tempVal.getValue());
            picklistToReturn.add(tempMap);
        }
        return picklistToReturn;
    }
    
    @AuraEnabled(cacheable=true)
    public static list<map<String,string>> getCustomerPresencePicklist(){
        list<map<String,string>> picklistToReturn = new list<map<String,string>>();
        Schema.DescribeFieldResult fieldResult = Appointment__c.CustomerPresenceConfirmation__c.getDescribe();
        for(Schema.PicklistEntry tempVal: fieldResult.getPicklistValues()){
            map<string,string> tempMap=new map<string,string>();
            tempMap.put('label',tempVal.getLabel());
            tempMap.put('value',tempVal.getValue());
            picklistToReturn.add(tempMap);
        }
        return picklistToReturn;
    }
    
    /**
* getResidencePicklist
*
* This method used to return all the residence picklist values
* @param  none
* @return select options
*/
    @AuraEnabled(cacheable=true)
    public static list<map<String,string>> getResidencePicklist(){
        list<map<String,string>> picklistToReturn = new list<map<String,string>>();
        Schema.DescribeFieldResult fieldResult = Appointment__c.Residency__c.getDescribe();
        for(Schema.PicklistEntry tempVal: fieldResult.getPicklistValues()){
            map<string,string> tempMap=new map<string,string>();
            tempMap.put('label',tempVal.getValue());
            tempMap.put('value',tempVal.getValue());
            picklistToReturn.add(tempMap);
        }
        return picklistToReturn;
    }
    
    /**
* getEmiratesPicklist
*
* This method used to return all the Emirates picklist values
* @param  none
* @return select options
*/
    @AuraEnabled(cacheable=true)
    public static list<map<String,string>> getEmiratesPicklist(){
        list<map<String,string>> picklistToReturn = new list<map<String,string>>();
        Schema.DescribeFieldResult fieldResult = Appointment__c.Emirates__c.getDescribe();
        for(Schema.PicklistEntry tempVal: fieldResult.getPicklistValues()){
            map<string,string> tempMap=new map<string,string>();
            tempMap.put('label',tempVal.getLabel());
            tempMap.put('value',tempVal.getValue());
            picklistToReturn.add(tempMap);
        }
        return picklistToReturn;
    }
    
    /**
* getCountyCodePicklist
*
* This method used to return all the County Code picklist values
* @param  none
* @return select options
*/
    @AuraEnabled(cacheable=true)
    public static list<map<String,string>> getCountyCodePicklist(){
        list<map<String,string>> picklistToReturn = new list<map<String,string>>();
        Schema.DescribeFieldResult fieldResult = Contact.MobileCountryCode__c.getDescribe();
        for(Schema.PicklistEntry tempVal: fieldResult.getPicklistValues()){
            map<string,string> tempMap=new map<string,string>();
            tempMap.put('label',tempVal.getLabel());
            tempMap.put('value',tempVal.getValue());
            picklistToReturn.add(tempMap);
        }
        return picklistToReturn;
    }
    
    /**
* getCancellationReasonPicklist
*
* This method used to return all the Cancellation Reason picklist values
* @param  none
* @return select options
*/
    @AuraEnabled(cacheable=true)
    public static list<map<String,string>> getCancellationReasonPicklist(){
        list<map<String,string>> picklistToReturn = new list<map<String,string>>();
        Schema.DescribeFieldResult fieldResult = Appointment__c.Cancellation_Reason__c.getDescribe();
        for(Schema.PicklistEntry tempVal: fieldResult.getPicklistValues()){
            map<string,string> tempMap=new map<string,string>();
            tempMap.put('label',tempVal.getLabel());
            tempMap.put('value',tempVal.getValue());
            picklistToReturn.add(tempMap);
        }
        return picklistToReturn;
    }
    
    /**
* getProjectLocations
*
* This method used to make the calllout with selected Project to get locations
* @param  none
* @return select options
*/
    @AuraEnabled(cacheable=false)
    public static list<map<String,string>>  getProjectLocations(User userRecord, String projectId){
        list<map<String,string>> mapToReturn = new list<map<String,string>>();
        Project__c projRecord = [select id,ProjectCode__c,AppointmentSystemCode__c,AppointmentSystemID__c from Project__c where id =:projectId limit 1];
        map<string,string> requestInnerMap = new map<string,string>();
        requestInnerMap.put('projectId',projRecord.AppointmentSystemID__c);
        requestInnerMap.put('agencyId',(userRecord.ContactId!=null ? userRecord.Account.AppointmentSystemID__c : '0'));
        map<string,object> requestMap = new map<string,object>();
        requestMap.put('getProjectLocReq',requestInnerMap);
        
        HttpResponse response = makeMuleCallout(JSON.serialize(requestMap), 'appointmentLocation');
        
        boolean success = (response!=null && (response.getStatusCode() == 200 || response.getStatusCode() == 201));
        if(success){
            map<string,object> responseMap = (map<String,object>) JSON.deserializeUntyped(response.getBody());
            list<object> resultList = (list<object>)responseMap.get('results');
            for(Object tempRec : resultList){
                map<string,object> resultMap = (map<string,object>)tempRec;
                map<string,string> tempMap=new map<string,string>();
                tempMap.put('label',String.ValueOf(resultMap.get('LocationName')));
                tempMap.put('value',String.ValueOf(resultMap.get('Id')));
                mapToReturn.add(tempMap);
            }
            //LoggerService.save(LoggerService.addApexServiceCalls('SUCCESS','AppointmentController','getProjectLocations',JSON.serialize(requestMap),response.getBody(),null));
        }else{
            LoggerService.save(LoggerService.addApexServiceCalls('FAIL','AppointmentController','getProjectLocations',JSON.serialize(requestMap),response.getBody(),null));
        }
        return mapToReturn;
    }
    
    /**
* getAvailableDates
*
* This method used to make the callout with selected locations to get available dates
* @param  none
* @return select options
*/
    @AuraEnabled(cacheable=false)
    public static list<map<String,string>>  getAvailableDates(User userRecord, String projectId,String locationId){
        list<map<String,string>> mapToReturn = new list<map<String,string>>();
        //Request
        Project__c projRecord = [select id,ProjectCode__c,Name,AppointmentSystemCode__c from Project__c where id =:projectId limit 1];
        User loggedInUser = [SELECT Id, Name, Profile.Name  FROM User WHERE Id =: UserInfo.getUserId()];
        String profileName = loggedInUser.Profile.Name;
        Map<Id, Contact> conMap = new Map<Id, Contact>([SELECT Id,UAENationalityVerified__c FROM Contact WHERE Id =: userRecord.ContactId]);
        
        map<string,string> requestInnerMap = new map<string,string>();
        requestInnerMap.put('locationId',locationId);
        if(profileName.equalsIgnoreCase(System.Label.AppointmentCCProfile)){
            requestInnerMap.put('category','CMAgent');
        }else{  
            //added by KP
            requestInnerMap.put('salesAgentId', loggedInUser.Id);
            if(userRecord.ContactId == null){ //For appointment booked from SF
                requestInnerMap.put('category',     BUYER);
            }else{ //For appointment booked from broker portal user
                requestInnerMap.put('category', conMap.get(userRecord.ContactId).UAENationalityVerified__c != null ? (conMap.get(userRecord.ContactId).UAENationalityVerified__c.equalsIgnoreCase('YES') ? EMIRATI : BROKER) : BROKER);
            }
        }
        requestInnerMap.put('projectCode',projRecord.AppointmentSystemCode__c);
        requestInnerMap.put('agencyId',(userRecord.ContactId!=null ? userRecord.Account.AppointmentSystemID__c : '0'));
        map<string,object> requestMap = new map<string,object>();
        requestMap.put('availableSlotDatesReq',requestInnerMap);
        
        HttpResponse response = makeMuleCallout(JSON.serialize(requestMap),'appointmentDate');
        
        //Parse response
        boolean success = (response!=null && (response.getStatusCode() == 200 || response.getStatusCode() == 201));
        if(success){
            map<string,object> responseMap = (map<String,object>) JSON.deserializeUntyped(response.getBody());
            list<object> resultList = (list<object>)responseMap.get('results');
            for(Object tempRec : resultList){
                map<string,string> tempMap=new map<string,string>();
                tempMap.put('label',String.ValueOf(tempRec));
                tempMap.put('value',String.ValueOf(tempRec));
                mapToReturn.add(tempMap);
            }
            //LoggerService.save(LoggerService.addApexServiceCalls('SUCCESS','AppointmentController','getAvailableDates',JSON.serialize(requestMap),response.getBody(),null));
        }else{
            LoggerService.save(LoggerService.addApexServiceCalls('FAIL','AppointmentController','getAvailableDates',JSON.serialize(requestMap),response.getBody(),null));
        }
        return mapToReturn;
    }
    
    /**
* getAvailableTimeSlots
*
* This method used to make the calllout with selected Date to get available slots
* @param  none
* @return select options
*/
    @AuraEnabled(cacheable=false)
    public static list<map<String,string>>  getAvailableTimeSlots(User userRecord, String projectId,String locationId, String selectedDate){
        list<map<String,string>> mapToReturn = new list<map<String,string>>();
        Project__c projRecord = [select id,ProjectCode__c,Name,AppointmentSystemCode__c from Project__c where id =:projectId limit 1];
        User loggedInUser = [SELECT Id, Name, Profile.Name  FROM User WHERE Id =: UserInfo.getUserId()];
        Map<Id, Contact> conMap = new Map<Id, Contact>([SELECT Id,UAENationalityVerified__c FROM Contact WHERE Id =: userRecord.ContactId]);
        
        String profileName = loggedInUser.Profile.Name;
        map<string,string> requestInnerMap = new map<string,string>();
        requestInnerMap.put('locationId',locationId);
        requestInnerMap.put('bookingDate',selectedDate);
        if(profileName.equalsIgnoreCase(System.Label.AppointmentCCProfile)){
            requestInnerMap.put('category','CMAgent');
        }else{
            //added by KP
            requestInnerMap.put('salesAgentId', loggedInUser.Id);
            if(userRecord.ContactId == null){ //For appointment booked from SF
                requestInnerMap.put('category',     BUYER);
            }else{ //For appointment booked from broker portal user
                requestInnerMap.put('category', conMap.get(userRecord.ContactId).UAENationalityVerified__c != null ? (conMap.get(userRecord.ContactId).UAENationalityVerified__c.equalsIgnoreCase('YES') ? EMIRATI : BROKER) : BROKER);
            }
        }
        requestInnerMap.put('projectCode',projRecord.AppointmentSystemCode__c);
        requestInnerMap.put('agencyId',(userRecord.ContactId!=null ? userRecord.Account.AppointmentSystemID__c : '0'));
        map<string,object> requestMap = new map<string,object>();
        requestMap.put('availableSlotTimeReq',requestInnerMap);
        
        HttpResponse response = makeMuleCallout(JSON.serialize(requestMap),'appointmentSlot');
        //Parse response
        boolean success = (response!=null && (response.getStatusCode() == 200 || response.getStatusCode() == 201));
        if(success){
            map<string,object> responseMap = (map<String,object>) JSON.deserializeUntyped(response.getBody());
            list<object> resultList = (list<object>)responseMap.get('results');
            for(Object tempRec : resultList){
                map<string,object> resultMap = (map<string,object>)tempRec;
                map<string,string> tempMap=new map<string,string>();
                // Below changes are added as part of BPM-346
                if(resultMap.containsKey('slot') && String.ValueOf(resultMap.get('slot')) != null ){
                    tempMap.put('label',String.ValueOf(resultMap.get('slot')));
                    tempMap.put('value',String.ValueOf(resultMap.get('slotid')));
                }else{
                    tempMap.put('Message',String.ValueOf(resultMap.get('Message')));
                }
                mapToReturn.add(tempMap);
                // Above changes are added as part of BPM-346
            }
            //LoggerService.save(LoggerService.addApexServiceCalls('SUCCESS','AppointmentController','getAvailableTimeSlots',JSON.serialize(requestMap),response.getBody(),null));
        }else{
            LoggerService.save(LoggerService.addApexServiceCalls('FAIL','AppointmentController','getAvailableTimeSlots',JSON.serialize(requestMap),response.getBody(),null));
        }
        return mapToReturn;
    }
    
    /**
* bookAppointment
*
* This method used to make the the final booking callout and create appointment system
* @param  none
* @return success or error message
*/
    @AuraEnabled(cacheable=false)
    public static string bookAppointment(User userRecord, String projectId, String appointmentId, map<string,string> requestInnerMap )
    {
        // Added By Moh Sarfaraj for ASF-1669 
        Boolean isScheduled = String.isNotBlank(appointmentId) && appointmentId != 'null' ? true: false;
        Boolean isBrokerRequest;
        string returnMsg='Internal Server Error';
        String recordId = requestInnerMap.get('recordId');
        String SFaccountId = requestInnerMap.get('accountId');
        String sObjectType = String.ValueOf(((ID)recordId).getSObjectType());
        String residentCityId;
        Project__c projRecord; 
        
        
        
        if(!isScheduled){
            //String leadId = requestInnerMap.remove('leadId');
            projRecord = new Project__c();
            projRecord = [select id,ProjectCode__c,Name,AppointmentSystemCode__c from Project__c where id =:projectId limit 1];
            isBrokerRequest = (userRecord.contactId != null); 
            String SalesAgentFullName = !isBrokerRequest ? userRecord.FirstName+' '+userRecord.LastName : ''; //To pass the sales manager name
            String SalesManagerDesignation = !isBrokerRequest ? userRecord.RoleName__c : ''; //To pass the sales manager Role
            String SalesManagerCompletePhoneNo_Extension = !isBrokerRequest ? userRecord.Extension : ''; //To pass the sales manager phone
            String SalesManagerEmail = !isBrokerRequest ? userRecord.Email : '';
            String CustomerId=requestInnerMap.get('accountId')!=null?requestInnerMap.get('accountId'):'';
            String ContactId=requestInnerMap.get('contactId')!=null?requestInnerMap.get('contactId'):'';
            //To pass the sales manager email
            Map<Id, Contact> conMap = new Map<Id, Contact>([SELECT Id,UAENationalityVerified__c FROM Contact WHERE Id =: userRecord.ContactId]);
            User loggedInUser = [SELECT Id, Name, Profile.Name FROM User WHERE Id =: UserInfo.getUserId()];
            String profileName = loggedInUser.Profile.Name;
            
            requestInnerMap.put('agencyId',(userRecord.ContactId!=null ? userRecord.Account.AppointmentSystemID__c : '0'));
            // Removing + (plus) from country codes added by Tharun
            String buyerPhoneCountryCode = requestInnerMap.get('phoneCountryCode');
            if(buyerPhoneCountryCode.contains('+')) { requestInnerMap.put('phoneCountryCode' , buyerPhoneCountryCode.replace('+','')); } 
            String brokPhoneCountryCode = requestInnerMap.get('brokerPhoneCountryCode');
            if(brokPhoneCountryCode.contains('+')) { requestInnerMap.put('brokerPhoneCountryCode' , brokPhoneCountryCode.replace('+','')); } 
            
            if(isBrokerRequest){
                requestInnerMap.put('leadType',userRecord.Contact.BrokerType__c);
                //Below BrokerManager__c added by Tharun as per BPM-308
                requestInnerMap.put('brokerManagerName',(userRecord.Contact.Account.BrokerManager__c != null ? userRecord.Contact.Account.BrokerManager__c : ''));
            }else{
                requestInnerMap.put('leadType','');
                requestInnerMap.remove('brokerFirstname');
                requestInnerMap.remove('brokerLastName');
                requestInnerMap.remove('brokerEmail');
                requestInnerMap.remove('brokerPhoneCountryCode');
                requestInnerMap.remove('brokerPhoneNumber');
            }
            
            requestInnerMap.put('projectCode',projRecord.AppointmentSystemCode__c);
            //Get the node name for Opportunity and update below // SARAN
            requestInnerMap.put('leadId',recordId); // Sending leadId for Both Lead and Opportunity object. Needs correction.
            
            //Defaulting the Values
            residentCityId = requestInnerMap.get('residentCityId');
            requestInnerMap.put('nationalityCode',((requestInnerMap.containsKey('nationality') && contryTOISO2Code.containsKey(requestInnerMap.get('nationality').toLowerCase()) ) ?  contryTOISO2Code.get(requestInnerMap.get('nationality').toLowerCase()) :'' ) );
            requestInnerMap.put('emiratesId', (requestInnerMap.containsKey('emiratesId')? requestInnerMap.get('emiratesId') : '' ) );
            requestInnerMap.put('passportExpirationDate',(requestInnerMap.containsKey('passportExpirationDate')? requestInnerMap.get('passportExpirationDate') : '' ) );
            requestInnerMap.put('passportNumber',(requestInnerMap.containsKey('passportNumber')? requestInnerMap.get('passportNumber') : '' ) );
            requestInnerMap.put('residentCityId',( ( requestInnerMap.containsKey('residentCityId') && residencyMap.containsKey(requestInnerMap.get('residentCityId')))? residencyMap.get(requestInnerMap.get('residentCityId')) : '1' ) );
            
            // Updated by Moh Sarfaraj for ASF-1814, ASF-1815 on 16 oct 2023 start
            if(profileName.equalsIgnoreCase(System.Label.AppointmentCCProfile)){
                requestInnerMap.put('categoryName','CMAgent');
                requestInnerMap.put('slotType','Internal');
            }else{
                //added by KP
                requestInnerMap.put('salesAgentId', loggedInUser.Id);
                if(userRecord.ContactId == null){ //For appointment booked from SF
                    requestInnerMap.put('categoryName', BUYER);                    
                }else{ //For appointment booked from broker portal user
                    requestInnerMap.put('categoryName', conMap.get(userRecord.ContactId).UAENationalityVerified__c != null ? (conMap.get(userRecord.ContactId).UAENationalityVerified__c.equalsIgnoreCase('YES') ? EMIRATI : BROKER) : BROKER);
                    requestInnerMap.put('slotType', 'Public');
                }
            }
            // Updated by Moh Sarfaraj for ASF-1814, ASF-1815 on 16 oct 2023 end
            
            requestInnerMap.put('bookingSource',(userRecord.ContactId!=null ? ONLINE+BROKER : ONLINE+BUYER) );
            requestInnerMap.put('salesAgentName',SalesAgentFullName);
            requestInnerMap.put('salesManagerEmail',SalesManagerEmail);
            requestInnerMap.put('salesManagerDesignation',SalesManagerDesignation);
            requestInnerMap.put('salesManagerCompletePhoneNo',SalesManagerCompletePhoneNo_Extension);
            requestInnerMap.put('customerId',CustomerId); //added by Amarjeet puri
            requestInnerMap.put('contactId',ContactId); //added by Amarjeet puri
            //added by Amarjeet puri till here
            
            requestInnerMap.put('bedroomId','0');
            requestInnerMap.put('clientType','0');
            requestInnerMap.put('numberOfBedrooms',(requestInnerMap.containsKey('numberOfBedrooms')? requestInnerMap.get('numberOfBedrooms') : '' ));
        }
        Map<String,Object> requestMap = new Map<String,Object>();
        
        HttpResponse response;
        if(!isScheduled){
            // Booking appointment
            requestMap.put('createNewBookingReq',requestInnerMap);
            response = new HttpResponse();
            response = makeMuleCallout(JSON.serialize(requestMap),'appointmentBooking');
        }else{
            // Added By Moh Sarfaraj for ASF-1669 
            // Rescheduling Booking appointment
            Map<String,Object> mapForReschduler = new Map<String, Object>();
            Appointment__c existingAppointment = new Appointment__c();
            existingAppointment = [SELECT Id,AppointmentId__c,Location__c FROM Appointment__c WHERE Id = :appointmentId LIMIT 1];
            mapForReschduler.put('bookingreferencenumber', existingAppointment.AppointmentId__c);
            mapForReschduler.put('locationid', existingAppointment.Location__c);  //added by Amarjeet puri
            mapForReschduler.put('bookingdate', requestInnerMap.get('bookingDate'));
            mapForReschduler.put('slot', requestInnerMap.get('bookingSlot'));
            mapForReschduler.put('slotid', requestInnerMap.get('slotId')); 
            response = new HttpResponse();
            
            
            // Calling Mulesoft Metadata to get Call out info.
            MuleSoftSetting__mdt  mulesoftAPI = Utilities.getMuleSoftDetails('appointmentReschedule');
            Organization org = Utilities.getOrganizationDetails();
            String endPointURL = mulesoftAPI.SandboxURL__c ;
            if(!org.IsSandbox){
                endPointURL = mulesoftAPI.ProductionURL__c ; 
            }
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setHeader('Content-Type','application/json');
            request.setHeader(mulesoftAPI.APIId__c, mulesoftAPI.APIKey__c);
            request.setHeader('Accept','*/*');
            request.setHeader('Accept-Encoding','gzip, deflate, br');
            request.setHeader('Connection','keep-alive');
            request.setTimeout(60000);
            request.setEndpoint(endPointURL);
            request.setMethod(mulesoftAPI.Method__c);
            request.setBody(JSON.serialize(mapForReschduler));
            
            
            if(!Test.isRunningTest()){
                response = http.send(request);
            }
            
        }
        LoggerService.save(LoggerService.addApexServiceCalls(response.getStatusCode()+' Status Code',
                                                             'AppointmentController',
                                                             'bookAppointment',
                                                             JSON.serialize(requestMap),
                                                             response.getBody(),null));
        //Parse response
        boolean success = (response!=null && (response.getStatusCode() == 200 || response.getStatusCode() == 201));
        if(success){
            if(!isScheduled){
               
                map<String,object> responseMap = (map<String,object>) JSON.deserializeUntyped(response.getBody());
                map<String,object> innerResultMap = (map<String,object>)responseMap.get('results');
                if(innerResultMap.containsKey('Message')){
                    returnMsg = String.ValueOf(innerResultMap.get('Message'));
                    
                    //LoggerService.save(LoggerService.addApexServiceCalls('AppointmentController','AppointmentController','bookAppointment',JSON.serialize(requestMap),response.getBody(),recordId));
                }
                
                if(innerResultMap.containsKey('bookingreferencenumber')){
                    //TODO Create the appointment record
                    Appointment__c recordToCreate = new Appointment__c();
                    recordToCreate.AppointmentId__c = String.ValueOf(innerResultMap.get('bookingreferencenumber'));
                    recordToCreate.Location_URL__c = String.ValueOf(innerResultMap.get('locationUrl')); // Add by Amarjeet Puri on 26-02-2015
                    recordToCreate.Broker__c = isBrokerRequest ? userRecord.id:null;
                    recordToCreate.Email__c =  requestInnerMap.get('email');
                    recordToCreate.Emirates__c = residentCityId;
                    //recordToCreate.Lead__c = requestInnerMap.get('leadId');
                    if(recordId!='' && recordId!=''){
                        if(sObjectType.equalsIgnoreCase('Lead')){
                            recordToCreate.Lead__c = requestInnerMap.get('recordId');
                        }else if(sObjectType.equalsIgnoreCase('Opportunity')){
                            recordToCreate.Opportunity__c = requestInnerMap.get('recordId');
                        }
                    }
                    recordToCreate.Mobile__c = requestInnerMap.get('phoneCountryCode')+requestInnerMap.get('phone');
                    recordToCreate.EmiratesId__c = requestInnerMap.get('emiratesId');
                    recordToCreate.Nationality__c = requestInnerMap.get('nationality');
                    recordToCreate.PassportExpiryDate__c = (requestInnerMap.get('passportExpirationDate')!=null && requestInnerMap.get('passportExpirationDate')!='') ? Date.ValueOf(requestInnerMap.get('passportExpirationDate')):null;
                    recordToCreate.PassportNumber__c = requestInnerMap.get('passportNumber');
                    recordToCreate.Project__c = projRecord.Id;
                    recordToCreate.Residency__c = requestInnerMap.get('residencyStatus');
                    recordToCreate.Slot__c = requestInnerMap.get('slotId');
                    recordToCreate.LocationName__c =innerResultMap.get('LocationName')!=null? String.ValueOf(innerResultMap.get('LocationName')):'';
                    recordToCreate.LocationNameArabic__c = innerResultMap.get('LocationNameArabic')!=null?String.ValueOf(innerResultMap.get('LocationNameArabic')):'';
                    recordToCreate.Contact__c = requestInnerMap.containsKey('contactId') && String.isNotBlank((String)requestInnerMap.get('contactId'))  ? (Id)requestInnerMap.get('contactId') : null; //added by AMARJEET PURI
                    if(!Test.isRunningTest()){
                        List<String> sttime=String.ValueOf(innerResultMap.get('slotStartTime')).split(' ');
                        List<String> edtime=String.ValueOf(innerResultMap.get('slotEndTime')).split(' ');                    
                        recordToCreate.StartTime__c = Datetime.valueOf('2025-01-01 ' +sttime[0]+':00 '+sttime[1] ).time();
                        recordToCreate.EndTime__c = Datetime.valueOf('2025-01-01 '  +edtime[0]+':00 '+edtime[1] ).time();
                    }
                    recordToCreate.Appointment_Status__c = BOOKED_STATUS;
                    recordToCreate.CustomerPresenceConfirmation__c = requestInnerMap.get('customerPresence');
                    
                    //to add encrypted recordid for booked appointment 
                    recordToCreate.EncryptedRecordId__c = String.valueOf(innerResultMap.get('RecordId'));
                    recordToCreate.Appointment_Location__c = requestInnerMap.get('selectedLocationValue');
                    recordToCreate.Location__c = requestInnerMap.get('locationId');
                    list<string> bookedDateString = requestInnerMap.get('bookingDate').split('/');
                    recordToCreate.Date__c = Date.newInstance(Integer.ValueOf(bookedDateString[2]),Integer.ValueOf(bookedDateString[0]), Integer.ValueOf(bookedDateString[1]));
                    recordToCreate.Appointment_Slot_Time__c = String.ValueOf(innerResultMap.get('bookingslot'));
                    insert recordToCreate;
                    returnMsg='success';
                }
            }else{
                // Added By Moh Sarfaraj for ASF-1669 
                if(!Test.isRunningTest()){
                    Map<String,Object> responseMap = (Map<String,object>) JSON.deserializeUntyped(response.getBody());
                    Date apptDate = Date.valueOf(String.valueOf(responseMap.get('bookingdate')));
                    Appointment__c recordToUpdate = new Appointment__c();
                    recordToUpdate.Id = appointmentId;
                    recordToUpdate.Date__c = apptDate;
                    recordToUpdate.Appointment_Slot_Time__c = String.valueOf(responseMap.get('slot'));
                    recordToUpdate.Slot__c = String.valueOf(responseMap.get('slotid')); 
                    update recordToUpdate;
                }
                return 'success';
            }
        }else{
            returnMsg = response != null ? String.valueOf(response.getStatusCode()) : '';
            LoggerService.save(LoggerService.addApexServiceCalls(response.getStatusCode()+' Status Code',
                                                                 'AppointmentController',
                                                                 'bookAppointment',
                                                                 JSON.serialize(requestMap),
                                                                 response.getBody(),recordId));
        }
        return returnMsg;
    }
    
    @AuraEnabled(cacheable=false)
    public static string convertLead(String recordId){
        try {
            List<Database.LeadConvertResult> lcr = UtilitiesWithoutSharing.convertLeadFromAppointment(recordId);
            //Get the Appointment by Lead
            List<Appointment__c> appList = [SELECT Id, Opportunity__c 
                                            FROM Appointment__c 
                                            WHERE Lead__c =:recordId 
                                            AND Appointment_Status__c=:BOOKED_STATUS 
                                            AND Date__c >= :System.Today()
                                            ORDER BY LastModifiedDate DESC 
                                            LIMIT 1]; //Only One Appointment can be present per lead
            if(!appList.isEmpty()){
                appList[0].Opportunity__c = lcr[0].getOpportunityId();
                update appList[0];
            }
            return 'success';
        } catch (Exception e) {
            LoggerService.save(LoggerService.addApexLog(e,'AppointmentController','convertLead',''));
            /*
String htmlEmailBody = 'Hello,</br></br> AppointmentController convertLead has failed because of below error.</br></br>';
htmlEmailBody += ' <b> ' + e.getMessage() + ' </b> </br> ' ;
htmlEmailBody +=  ' <b> ' + e.getStackTraceString() + ' </b> ' ;
htmlEmailBody +=  ' <b> parameters : recordId = ' + recordId+' </b> ' ;
List<String> recipientList = Label.SysAdminEmailAddress.split(';');
Utilities.sendEmail(new list<Messaging.SingleEmailMessage>{Utilities.getEmailInstance('','','',recipientList, new List<String>(), new List<String>(), 'Broker Lead Conversion Failure', '',htmlEmailBody,new List<Messaging.EmailFileAttachment>(), '')});
*/
            return e.getMessage();
        }
    }
    
    /**
* cancelBookedAppointment
* This method used to make the the cancellation on the booking made earlier - callout to update appointment system
* @param  recordId //Lead or Contact ID, requestInnerMap //Contains Request Body
* @return success or error message
*/
    @AuraEnabled(cacheable=false)
    public static string cancelBookedAppointment(String recordId, map<string,string> requestInnerMap ){
        //Get the Appointment by Lead or Contact Record Id
        // Updated By Moh Sarfaraj for BPE-105
        List<Appointment__c> appList = [SELECT Id, Name, Appointment_Status__c, AppointmentId__c 
                                        FROM Appointment__c  
                                        WHERE (Id = :recordId OR Lead__c =:recordId OR Contact__c =:recordId OR Opportunity__c =:recordId) 
                                        AND Appointment_Status__c=:BOOKED_STATUS AND Date__c >= :System.Today() LIMIT 1]; //Only One Appointment can be present per lead
        Id appointmentRecordId = !appList.isEmpty() ? appList[0].Id : null;
        try {
            
            
            if(!appList.isEmpty()) {
                //This is not bulkified as the Endpoint is not accepting it
                Appointment__c appointment = appList[0];
                IS_PASS_PARAMETER_ON_URL = true; //So that we can append parameters on the URL
                PARAMETER_TO_PASS = appointment.AppointmentId__c; //The parameter to append on the url can be pass here
               
                
                String endPointURL = null;
                MuleSoftSetting__mdt  mulesoftAPI = Utilities.getMuleSoftDetails('appointmentCancellation');
                Organization org = Utilities.getOrganizationDetails();
                endPointURL = mulesoftAPI.SandboxURL__c ;
                if(!org.IsSandbox){
                    endPointURL = mulesoftAPI.ProductionURL__c ; 
                }
                //TILL MULE IS ENABLED
                endPointURL = endPointURL+PARAMETER_TO_PASS; //'https://appointmentbookingapisit.aldar.com/api/booking/cancelbooking/'
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setHeader('Content-Type','application/json');
                String theProcess = mulesoftAPI.APIKey__c+' - '+mulesoftAPI.APIId__c+' - ';
                if(mulesoftAPI.APIId__c == Label.AppointmentSystemKEY) { //Move to custom label SS before deployment
                    //Mule is not ready, so reading value from here
                    theProcess = theProcess+' - INSIDE - ';
                    request.setHeader(mulesoftAPI.APIId__c,mulesoftAPI.APIKey__c);
                } else {
                    //Once mule ready, APIKey__c will be updated so it will call mule automatically
                    request.setHeader('client_secret',mulesoftAPI.APIKey__c);
                    request.setHeader('client_id',mulesoftAPI.APIId__c);
                }
                request.setTimeout(60000);
                request.setEndpoint(endPointURL);
                request.setMethod('POST');
                request.setBody(JSON.serialize(requestInnerMap));
               
                HttpResponse response = http.send(request);
                
                //System.HttpResponse[Status=Unauthorized, StatusCode=401]
                
                IS_PASS_PARAMETER_ON_URL = false;
                PARAMETER_TO_PASS = null;
                LoggerService.save(LoggerService.addApexServiceCalls('AppointmentController','cancelBookedAppointment','Appointment Cancellation '+recordId,(JSON.serialize(requestInnerMap).length() < 131072 ? JSON.serialize(requestInnerMap) : ''),response.getBody(),null));
                //Update the Appointment__c record once cancelled
                //appointment.Cancellation_Reason__c = requestInnerMap.get('cancelreason');
                appointment.Cancellation_Comment__c = requestInnerMap.get('message');
                appointment.Appointment_Status__c = CANCELLED_STATUS;
                // Added BY Moh Sarfaraj for BPE-133
                if(isRunningFromBackEnd){
                    appointment.IsCancelledByManager__c = true;
                }
                if(response.getStatusCode() == 200 || response.getStatusCode() == 201 || response.getStatusCode() == 204) {
                    update appointment;
                }else {
                    return JSON.serialize(response.getBody());
                }
                
                return 'success';
            }
            return 'No Appointment is there to cancel';
        } catch(Exception ex) {
            captureExceptionLogger(ex, 'Appointment Cancellation', appointmentRecordId, 'cancelBookedAppointment');
            return ex.getMessage();
        }
    }
    
    /*To Log the Exception
* Pass null to appointmentRecordId if not for appointment
*/
    public static void captureExceptionLogger(Exception ex, String processName,  Id appointmentRecordId, String methodName) {
        Logger__c lgs = LoggerService.saveAndReturnLogger(LoggerService.createApexLog(ex,processName,'AppointmentController',methodName));
        if(appointmentRecordId!=null) {
            Appointment__c appointment = new Appointment__c(Id=appointmentRecordId,Logger_Id__c=lgs.Id );
            update appointment;
        }
    }
    /**
* processNewBrokerAgency
*
* This method used to make HTTP callout to appointment system to CreateUpdate Agency
* @param  recordIds from Flow-Account_After_Insert_Update
* @return void
*/
    @InvocableMethod
    public static void processNewBrokerAgency(List<Id> recordIds) {
       
        if(!System.isBatch() && !System.isQueueable() && !System.isFuture()) {
            processNewBrokerAgencyFuture(recordIds);
        }else if(System.isBatch() && Trigger.isExecuting){
            
            System.enqueueJob(new processNewBrokerAgencyQueueable(recordIds));
        }
    }
    
    @future(callout=true)
    public static void processNewBrokerAgencyFuture(List<Id> recordIds) {
       
        callAppSystemOnCreateUpdate(recordIds);
    }
    
    //Queueable class
    public class processNewBrokerAgencyQueueable implements Queueable,Database.AllowsCallouts {
        List<Id> recordIds = new List<Id>(); 
        public processNewBrokerAgencyQueueable(List<Id> accIds){
            recordIds = accIds;
        }
        public void execute(QueueableContext context){
            callAppSystemOnCreateUpdate(recordIds);
        }
    }
    
    public static void callAppSystemOnCreateUpdate(List<Id> recordIds)
    {
        
        List<Object> finalRequestParam = new List<Object>();
        // Updated By Moh Sarfaraj for BPM-457, BPM-550
        Map<Id, Account> accMap = new Map<Id, Account>([SELECT Id, Name, ERPID__c, BillingState, BillingCountry,AppointmentSystemID__c,AgencyStatus__c,
                                                        BrokerPremiumClassification__c, Broker_Classification_Formula__c, AllowAdditionalAppointmentSlots__c,
                                                        AdditionalAppointmentSlots__c,
                                                        AgencyCategory__c,AgencySubCategory__c, ParentId, Parent.ParentId,AllowDigitalSale__c
                                                        FROM Account 
                                                        WHERE Id IN:recordIds]);
        String requestParam = null;
        //Below code need to modify
        //Id accId = !accMap.values().isEmpty() ? accMap.values()[0].Id : null;
        try{
            for(Account acc:accMap.values()) {
                Map<String, Object> singleAccountObject = new Map<String, Object>();
                singleAccountObject.put('AgencyId',         String.isBlank(acc.AppointmentSystemID__c) ? '' : acc.AppointmentSystemID__c);
                singleAccountObject.put('AgencyType',       acc.BillingCountry == 'United Arab Emirates' ? 'Regional Brokers' : 'International Brokers');
                singleAccountObject.put('AgencyName',       acc.Name);
                singleAccountObject.put('ERPId',            acc.ERPID__c);
                singleAccountObject.put('AgencyLocation',   acc.BillingCountry == 'United Arab Emirates' ? acc.BillingState : 'International');
                singleAccountObject.put('AgencyCountry', 	acc.BillingCountry);
                singleAccountObject.put('IsClassifiedBroker',acc.BrokerPremiumClassification__c);
                singleAccountObject.put('ClassificationType',acc.Broker_Classification_Formula__c);
                singleAccountObject.put('SFId', acc.Id);
                singleAccountObject.put('AgencyCategory',   acc.AgencyCategory__c);
                singleAccountObject.put('AgencySubCategory',  acc.AgencySubCategory__c); // Added By Moh Sarfaraj for BPM-550
                singleAccountObject.put('ParentAgencySFId', acc?.ParentId);
                singleAccountObject.put('IsOnlineBookingEnabled', acc.AllowDigitalSale__c);
                //singleAccountObject.put('GrandParentAgencySFId', acc?.Parent?.ParentId);
                
                // Added By Moh Sarfaraj for BPM-457
                singleAccountObject.put('IsPriorityAgency',   acc.AllowAdditionalAppointmentSlots__c);
                singleAccountObject.put('PrioritySlots',   acc.AdditionalAppointmentSlots__c);
                singleAccountObject.put('Actor',   UserInfo.getName());
                //Agency Status
                singleAccountObject.put('AgencyStatus', acc.AgencyStatus__c);
                if(acc.AgencyStatus__c == 'Suspended' || acc.AgencyStatus__c == 'Blocked' || acc.AgencyStatus__c == 'Closed'){
                    singleAccountObject.put('IsPermanentBlocked', true);
                }else {
                    singleAccountObject.put('IsPermanentBlocked', false);
                }
                finalRequestParam.add(singleAccountObject);
                /*
accId = acc.Id;
String AgencyType = 'International Brokers';
String BillingState = 'International';
String appSysId = String.isBlank(acc.AppointmentSystemID__c) ? '' : acc.AppointmentSystemID__c;
if(acc.BillingCountry == 'United Arab Emirates') {
AgencyType = 'Regional Brokers';
BillingState = acc.BillingState;
}
requestParam = '{"AgencyId": "'+appSysId+'", "AgencyType": "'+AgencyType+'", "AgencyName": "'+acc.Name+'", "ERPId": "'+acc.ERPID__c+'","AgencyLocation": "'+BillingState+'","IsClassifiedBroker": "'+acc.BrokerPremiumClassification__c+'","ClassificationType": "'+acc.Broker_Classification_Formula__c+'","SFId": "'+acc.Id+'"}';
break;
*/
            }
            
            String endPointURL = null;
            MuleSoftSetting__mdt  mulesoftAPI = Utilities.getMuleSoftDetails('appointmentCreateUpdateAgency');
            Organization org = Utilities.getOrganizationDetails();
            endPointURL = mulesoftAPI.SandboxURL__c ;
            if(!org.IsSandbox){
                endPointURL = mulesoftAPI.ProductionURL__c ; 
            }
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setHeader('Content-Type','application/json');
            String theProcess = mulesoftAPI.APIKey__c+' - '+mulesoftAPI.APIId__c+' - ';
            if(mulesoftAPI.APIId__c == Label.AppointmentSystemKEY) {
                
                theProcess = theProcess+' - INSIDE - ';
                request.setHeader(mulesoftAPI.APIId__c,mulesoftAPI.APIKey__c);
            } else {
                
                request.setHeader('client_secret',mulesoftAPI.APIKey__c);
                request.setHeader('client_id',mulesoftAPI.APIId__c);
            }
            request.setTimeout(60000);
            request.setEndpoint(endPointURL);
            request.setMethod('POST');
            
            request.setBody(JSON.serialize(finalRequestParam));
            
            HttpResponse response = http.send(request);
           
            LoggerService.save(LoggerService.addApexServiceCalls('AppointmentController','callAppSystemOnCreateUpdate','Broker Agency Create Or Update---',(JSON.serialize(finalRequestParam).length() < 131072 ? JSON.serialize(finalRequestParam) : ''),response.getBody(),null));
            
            List<Object> responseListObject = (List<Object>) JSON.deserializeUntyped(response.getBody());
            List<Account> accountsToBeUpdatedList = new List<Account>();
            if(!System.isBatch() && !System.isQueueable() && (response.getStatusCode() == 200 || response.getStatusCode() == 201 || response.getStatusCode() == 204)) {
                for(Object responseObject : responseListObject){
                    Map<String, Object> responseMap = (Map<String, Object>) responseObject;
                    if(responseMap.containsKey('AgencyId') && (String.ValueOf(responseMap.get('AgencyId')) != null)){
                        
                        Account account = new Account(Id=String.ValueOf(responseMap.get('SFId')), AppointmentSystemID__c=String.ValueOf(responseMap.get('AgencyId')));
                        accountsToBeUpdatedList.add(account);
                    }
                }
            }
            
            if(accountsToBeUpdatedList != null && accountsToBeUpdatedList.size() > 0){
                update accountsToBeUpdatedList;
            }
            
            /*
if(accId!=null && (response.getStatusCode() == 200 || response.getStatusCode() == 201 || response.getStatusCode() == 204)) {

Account account = new Account(Id=accId, AppointmentSystemID__c=String.ValueOf(responseMap.get('AgencyId')));
update account;
}
*/
        } catch(Exception ex) {
            captureExceptionLogger(ex, 'Broker Agency Create Or Update - Exception', null, 'callAppSystemOnCreateUpdate');
        }
    }
    
    /**
* makeMuleCallout
*
* This method used to make HTTP callout to appointment system
* @param  none
* @return HttpResponse result
*/
    static HttpResponse makeMuleCallout(string RequestBody,String muleConfig){
        //Intergation
        MuleSoftSetting__mdt  mulesoftAPI = Utilities.getMuleSoftDetails(muleConfig);
        Organization org = Utilities.getOrganizationDetails();
        String endPointURL = mulesoftAPI.SandboxURL__c ;
        if(!org.IsSandbox){
            endPointURL = mulesoftAPI.ProductionURL__c ; 
        }
        if(IS_PASS_PARAMETER_ON_URL) {
            endPointURL = endPointURL+'/'+PARAMETER_TO_PASS;
        }
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setHeader('Content-Type','application/json');
        request.setHeader('client_secret',mulesoftAPI.APIKey__c);
        request.setHeader('client_id',mulesoftAPI.APIId__c);
        request.setTimeout(60000);
        request.setEndpoint(endPointURL);
        request.setMethod(mulesoftAPI.Method__c);
        request.setBody(RequestBody);
        
        HttpResponse response = http.send(request);
       
        return response;
    }
    
    
    /**
* hasFutureAppoitment
*
* This method used to return associated future appointments
* @param  none
* @return User data
* SARAN Updated on 25-11, Return from Boolean to list and added more fields on the query and LIMIT 1
*/
    @AuraEnabled(cacheable=false)
    public static list<Appointment__c> hasFutureAppoitment(String recordId){
        // Updated By Moh Sarfaraj for BPE-105
        List<Appointment__c> appointmentRecords = [SELECT Id, Appointment_Status__c, Appointment_Slot_Time__c, 
                                                   Location__c, Project__c,
                                                   Appointment_Location__c, Date__c, Slot__c, AppointmentId__c
                                                   FROM Appointment__c 
                                                   WHERE (Lead__c = :recordId OR Opportunity__c=:recordId OR Contact__c = :recordId) 
                                                   AND Date__c >= :System.Today()
                                                   AND Appointment_Status__c=:BOOKED_STATUS ORDER BY CreatedDate DESC LIMIT 1];
        
        return appointmentRecords;
        //return null;
    }
    /**
* BuyerDetails
*
* Wrapper class to store the buyer details
*/
    
    public class BuyerDetails {
        @AuraEnabled
        public String sObjectType;
        @AuraEnabled
        public String sObjectId;
        @AuraEnabled
        public String accountId; // Added accountId Added by Amarjeet
        @AuraEnabled
        public String contactId; // Added ContactId Added by Amarjeet
        @AuraEnabled
        public String firstName;
        @AuraEnabled
        public String lastName;
        @AuraEnabled
        public String email;
        @AuraEnabled
        public String mobile;
        @AuraEnabled
        public String mobileCode;
        @AuraEnabled
        public String nationality;
        @AuraEnabled
        public String residence;
        @AuraEnabled
        public String emirates;
        @AuraEnabled
        public String nationalId;
        @AuraEnabled
        public String passport;
        @AuraEnabled
        public Date passportExpiration;
        // Tharun added
        @AuraEnabled
        public String numberOfBedrooms;
        
        public BuyerDetails() {}
        
        public BuyerDetails(Contact tempRecord) {
            sObjectType = 'Contact';
            sObjectId = tempRecord.Id;
            accountId = tempRecord.AccountId; //Added by Amarjeet puri
            contactId = tempRecord.Id; //Added by Amarjeet puri
            firstName = tempRecord.FirstName;
            lastName = tempRecord.LastName;
            email = tempRecord.Email;
            mobile = tempRecord.MobilePhone__c;
            mobileCode = tempRecord.MobileCountryCode__c;
            nationality = tempRecord.Nationality__c;
            residence = tempRecord.ResidentStatus__c;
            emirates = tempRecord.CustomerLocation__c;
            nationalId = tempRecord.NationalIdNumber__c;
            passport = tempRecord.PassportNumber__c;
            passportExpiration = tempRecord.PassportExpiryDate__c;
        }
        
        public BuyerDetails(Opportunity tempRecord) {
            sObjectType = 'Opportunity';
            sObjectId = tempRecord.Contact__r.Id;
            accountId = tempRecord.AccountId; // Set accountId
            firstName = tempRecord.Contact__r.FirstName;
            lastName = tempRecord.Contact__r.LastName;
            email = tempRecord.Contact__r.Email;
            mobile = tempRecord.Contact__r.MobilePhone__c;
            mobileCode = tempRecord.Contact__r.MobileCountryCode__c;
            nationality = tempRecord.Contact__r.Nationality__c;
            residence = tempRecord.Contact__r.ResidentStatus__c;
            emirates = tempRecord.Contact__r.CustomerLocation__c;
            nationalId = tempRecord.Contact__r.NationalIdNumber__c;
            passport = tempRecord.Contact__r.PassportNumber__c;
            passportExpiration = tempRecord.Contact__r.PassportExpiryDate__c;
            numberOfBedrooms = String.isBlank(tempRecord.NumberOfBedrooms__c) ? 'None' : tempRecord.NumberOfBedrooms__c;
        }
        
        public BuyerDetails(Lead tempRecord) {
            sObjectType = 'Lead';
            sObjectId = tempRecord.Id;
            //  accountId = tempRecord.AccountId; // Set accountId (if exists)
            firstName = tempRecord.FirstName;
            lastName = tempRecord.LastName;
            email = tempRecord.Email;
            mobile = tempRecord.MobileNumber1__c;
            mobileCode = tempRecord.MobileCountryCode__c;
            nationality = tempRecord.Nationality__c;
            residence = tempRecord.ResidentStatus__c;
            emirates = tempRecord.CustomerLocation__c;
            nationalId = tempRecord.NationalId__c;
            passport = tempRecord.PassportNumber__c;
            passportExpiration = tempRecord.PassportExpiryDate__c;
            numberOfBedrooms = String.isBlank(tempRecord.NumberOfBedrooms__c) ? 'None' : tempRecord.NumberOfBedrooms__c;
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static List<Map<String, String>> getEventProjects(){
        List<Map<String,String>> mapToReturn = new List<Map<String,String>>();
        
        for(String eachValue : System.Label.BPEAldarExpertProjectName.split(',')){
            Map<String,String> tempMap = new Map<String,String>();
            tempMap.put('label', eachValue.trim());
            tempMap.put('value', eachValue.trim());
            mapToReturn.add(tempMap);
        }
        return mapToReturn;
    }
    
    /**
* getEventProjectDetails
* This method used to make the calllout to get Project Details for Aldar Experts
* @param  none
* @return select options
* @description Added By Moh Sarfaraj for BPE-105
*/
    @AuraEnabled(cacheable=false)
    public static List<Map<String, String>> getEventProjectDetails(String projectName){
        List<Map<String,String>> mapToReturn = new List<Map<String,String>>();
        //requestBody
        Map<String,Object> requestInnerMap = new Map<String,Object>();
        requestInnerMap.put('ProjectCode', projectName); //System.Label.BPEAldarExpertProjectName
        requestInnerMap.put('ProjectName', null);
        requestInnerMap.put('IsInternalSoldOut', false);
        requestInnerMap.put('IsPublicSoldOut', false);
        requestInnerMap.put('CRMProjectName', null);
        
        HttpResponse response = new HttpResponse(); 
        if(!Test.isRunningTest()){
            response = makeMuleCallout(JSON.serialize(requestInnerMap), 'aldarExpertsProject');
        }
        
        Boolean success = (response!=null && (response.getStatusCode() == 200 || response.getStatusCode() == 201));
        if(success){
            Map<String,Object> responseMap = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
            List<object> resultList = (list<object>)responseMap.get('results');
            for(Object tempRec : resultList){
                Map<String,Object> resultMap = (Map<String,Object>)tempRec;
                Map<String,String> tempMap = new Map<String,String>();
                tempMap.put('label', String.valueOf(resultMap.get('ProjectName')));
                tempMap.put('value', String.valueOf(resultMap.get('ProjectId')));
                mapToReturn.add(tempMap);
            }
        }
        return mapToReturn;
    }
    
    /**
* getEventProjectLocations
* This method used to make the calllout to get Project Location Details for Aldar Experts
* @param  User
* @param  String
* @return List<Map<String,string>>
* @description Added By Moh Sarfaraj for BPE-105
*/
    @AuraEnabled(cacheable=false)
    public static List<Map<String, String>> getEventProjectLocations(User userRecord, String projectId){
        List<Map<String,String>> mapToReturn = new List<Map<String,String>>();
        //requestBody
        Map<String,String> requestInnerMap = new Map<String,String>();
        requestInnerMap.put('projectId', projectId);
        requestInnerMap.put('agencyId', userRecord.Account.AppointmentSystemID__c);
        
        Map<String,Object> requestMap = new Map<String,Object>();
        requestMap.put('getProjectLocReq', requestInnerMap);
        
        HttpResponse response = new HttpResponse();
        if(!Test.isRunningTest()){
            response = makeMuleCallout(JSON.serialize(requestMap), 'appointmentLocation');
        }
        Boolean success = (response!=null && (response.getStatusCode() == 200 || response.getStatusCode() == 201));
        if(success){
            Map<String,Object> responseMap = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
            List<object> resultList = (list<object>)responseMap.get('results');
            for(Object tempRec : resultList){
                Map<String,Object> resultMap = (Map<String,Object>)tempRec;
                Map<String,String> tempMap = new Map<String,String>();
                tempMap.put('label', String.valueOf(resultMap.get('LocationName')));
                tempMap.put('value', String.valueOf(resultMap.get('Id')));
                mapToReturn.add(tempMap);
            }
        }
        return mapToReturn;
    }
    
    /**
* getEventAvailableDates
* This method used to make the calllout to get Project Location Details for Aldar Experts
* @param  User
* @param  String
* @return List<Map<String,string>>
* @description Added By Moh Sarfaraj for BPE-105
*/
    @AuraEnabled(cacheable=false)
    public static List<Map<String, String>> getEventAvailableDates(User userRecord, String locationId, String projectName){
        List<Map<String,String>> mapToReturn = new List<Map<String,String>>();
        
        Map<String,String> requestInnerMap = new Map<String,String>();
        requestInnerMap.put('locationId', locationId);
        requestInnerMap.put('category','events');
        requestInnerMap.put('projectCode', projectName); //System.Label.BPEAldarExpertProjectName
        requestInnerMap.put('agencyId', userRecord.Account.AppointmentSystemID__c);
        Map<String,Object> requestMap = new Map<String,Object>();
        requestMap.put('availableSlotDatesReq', requestInnerMap);
        
        HttpResponse response = makeMuleCallout(JSON.serialize(requestMap), 'appointmentDate');
        
        Boolean success = (response!=null && (response.getStatusCode() == 200 || response.getStatusCode() == 201));
        if(success){
            Map<String,Object> responseMap = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
            List<object> resultList = (List<object>)responseMap.get('results');
            for(Object tempRec : resultList){
                Map<String,String> tempMap = new Map<String,String>();
                tempMap.put('label', String.valueOf(tempRec));
                tempMap.put('value', String.valueOf(tempRec));
                mapToReturn.add(tempMap);
            }
        }
        return mapToReturn;
    }
    
    /**
* getEventAvailableTimeSlots
* This method used to make the calllout with selected Date to get available slots Details for Aldar Experts
* @param  User
* @param  String
* @param  String
* @return List<Map<String,string>>
* @description Added By Moh Sarfaraj for BPE-105
*/
    @AuraEnabled(cacheable=false)
    public static List<Map<String,string>> getEventAvailableTimeSlots(User userRecord, String locationId, String selectedDate, String projectName){    
        List<Map<String,String>> mapToReturn = new List<Map<String,String>>();
        //Request
        Map<String,String> requestInnerMap = new Map<String,String>();
        requestInnerMap.put('locationId', locationId);
        requestInnerMap.put('bookingDate', selectedDate);
        requestInnerMap.put('category', 'events');
        requestInnerMap.put('projectCode', projectName); //  System.Label.BPEAldarExpertProjectName
        requestInnerMap.put('agencyId', userRecord.Account.AppointmentSystemID__c);
        
        Map<String,Object> requestMap = new Map<String,Object>();
        requestMap.put('availableSlotTimeReq', requestInnerMap);
        
        HttpResponse response = makeMuleCallout(JSON.serialize(requestMap),'appointmentSlot');
        
        //Parse response
        boolean success = (response!=null && (response.getStatusCode() == 200 || response.getStatusCode() == 201));
        if(success){
            Map<String,Object> responseMap = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
            List<Object> resultList = (List<Object>)responseMap.get('results');
            for(Object tempRec : resultList){
                Map<String,Object> resultMap = (Map<String,Object>)tempRec;
                Map<String,String> tempMap = new Map<String,String>();
                tempMap.put('label', String.valueOf(resultMap.get('slot')));
                tempMap.put('value', String.valueOf(resultMap.get('slotid')));
                mapToReturn.add(tempMap);
            }
        }
        return mapToReturn;
    }
    
    /**
* bookEventAppointment
* This method used to make the the final booking callout and create appointment for aldar experts
* @param  User
* @param  Map<String,String>
* @param  Boolean
* @return String
* @description Added By Moh Sarfaraj for BPE-105
*/
    @AuraEnabled(cacheable=false)
    public static string bookEventAppointment(User userRecord, Map<String,String> requestInnerMap, Boolean isUpdateUserDetails){
        String returnMsg = 'Internal Server Error';
        String recordId = userRecord.ContactId;
        
        Map<String,Object> requestMap = new Map<String,Object>();
        requestMap.put('createNewBookingReq', requestInnerMap);
        // Booking appointment
        HttpResponse response = new HttpResponse();
        response = makeMuleCallout(JSON.serialize(requestMap),'appointmentBooking');
        
        //Parse response
        boolean success = (response!=null && (response.getStatusCode() == 200 || response.getStatusCode() == 201));
        if(success){
            Map<String,Object> responseMap = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
            Map<String,Object> innerResultMap = (Map<String,Object>)responseMap.get('results');
            if(innerResultMap.containsKey('Message')){
                returnMsg = String.valueOf(innerResultMap.get('Message'));
                LoggerService.save(LoggerService.addApexServiceCalls('AppointmentController','AppointmentController','bookEventAppointment',JSON.serialize(requestMap),response.getBody(),recordId));
            }
            if(innerResultMap.containsKey('bookingreferencenumber')){
                // Create the appointment record
                String aldarExpertRecordTypeId = Schema.SObjectType.Appointment__c.getRecordTypeInfosByDeveloperName().get('AldarExperts').getRecordTypeId();
                
                Appointment__c recordToCreate = new Appointment__c();
                recordToCreate.RecordTypeId = aldarExpertRecordTypeId;
                recordToCreate.AppointmentId__c = String.ValueOf(innerResultMap.get('bookingreferencenumber'));
                recordToCreate.Broker__c = userRecord.Id;
                recordToCreate.Email__c =  requestInnerMap.get('email');
                recordToCreate.Contact__c = userRecord.ContactId;
                recordToCreate.Mobile__c = requestInnerMap.get('phoneCountryCode')+requestInnerMap.get('phone');
                recordToCreate.EmiratesId__c = requestInnerMap.get('emiratesId');
                recordToCreate.Nationality__c = requestInnerMap.get('nationality');
                recordToCreate.PassportNumber__c = requestInnerMap.get('passportNumber');
                recordToCreate.Residency__c = requestInnerMap.get('residencyStatus');
                recordToCreate.Slot__c = requestInnerMap.get('slotId');
                recordToCreate.Appointment_Status__c = BOOKED_STATUS;
                recordToCreate.EncryptedRecordId__c = String.valueOf(innerResultMap.get('RecordId'));
                recordToCreate.Appointment_Location__c = requestInnerMap.get('selectedLocationValue');
                recordToCreate.Location__c = requestInnerMap.get('locationId');
                recordToCreate.EventName__c = requestInnerMap.get('projectName');
                
                List<String> bookedDateString = requestInnerMap.get('bookingDate').split('/');
                recordToCreate.Date__c = Date.newInstance(Integer.valueOf(bookedDateString[2]),Integer.valueOf(bookedDateString[0]), Integer.valueOf(bookedDateString[1]));
                recordToCreate.Appointment_Slot_Time__c = String.valueOf(innerResultMap.get('EnquirySlot'));
                insert recordToCreate;
                
                if(isUpdateUserDetails){
                    Contact objContact = new Contact(
                        Id = recordId, 
                        MobileCountryCode__c = requestInnerMap.get('phoneCountryCode'),
                        MobilePhone__c = requestInnerMap.get('phone')
                    );
                    //update objContact;
                }   
                returnMsg ='{"result": "success", "recordId": "'+recordToCreate.AppointmentId__c+'"}';
            }
        }else{
            returnMsg = response != null ? String.valueOf(response.getStatusCode()) : '';
            LoggerService.save(LoggerService.addApexServiceCalls(response.getStatusCode()+'-- Status Code','AppointmentController','bookEventAppointment',JSON.serialize(requestMap),response.getBody(),recordId));
        }
        return returnMsg;
    }
    
    /**
* getEventAllAppointments
* This method used to make the to get all aldar experts appointments. 
* @param  String
* @return List<Appointment__c>
* @description Added By Moh Sarfaraj for BPE-105
*/
    @AuraEnabled(cacheable=false)
    public static List<Appointment__c> getEventAllAppointments(String recordId){
        String aldarExpertRecordTypeId = Schema.SObjectType.Appointment__c.getRecordTypeInfosByDeveloperName().get('AldarExperts').getRecordTypeId();
        List<Appointment__c> appointmentRecords = [SELECT Id, EventName__c, Appointment_Status__c, Appointment_Slot_Time__c,IsCancelledByManager__c,
                                                   Location__c, Project__c,Appointment_Location__c, Date__c, Slot__c, 
                                                   AppointmentId__c FROM Appointment__c WHERE RecordTypeId = :aldarExpertRecordTypeId AND 
                                                   Contact__c = :recordId
                                                   AND Date__c >= :System.Today() ORDER BY CreatedDate DESC LIMIT 2];
        
        if(appointmentRecords != null && !appointmentRecords.isEmpty()){
            return appointmentRecords;
        }else{
            return new List<Appointment__c>();
        }
    }  
    
    /**
* cancelBookedAppointmentFromQuickAction
* This method used to make the the cancellation on the booking made earlier - callout to update appointment system
* @param  String 
* @return String success or error message
* @description Added By Moh Sarfaraj for BPE-105
*/
    @AuraEnabled(cacheable=false)
    public static string cancelBookedAppointmentFromQuickAction(String recordId){
        Map<String,String> requestInnerMap = new Map<String,String>{'cancelreason'=>'Others','message'=>'Cancelled From Backend Manager'};
            isRunningFromBackEnd = true;
        String cancelResponse = cancelBookedAppointment(recordId, requestInnerMap);
        return cancelResponse;
    }
    
    /**
* MakeCalloutForAgent
*
* This method used to make HTTP callout to appointment system to CreateUpdate Agent
* Added By Dinesh Kumar
*/    
    @future(callout=true)
    public static void processContactFuture(List<Id> contactIds) {
        
        
        Map<Id, Contact> contactMap = new Map<Id, Contact>(
            [SELECT Id, Name, Email, AccountId, AllowAdditionalAppointmentSlots__c, 
             AdditionalAppointmentSlots__c, AgentStatus__c, 
             Account.AppointmentSystemID__c, LastModifiedBy.Username , LastModifiedBy.Email
             FROM Contact
             WHERE Id IN :contactIds]
        );
        
        Map<Id, User> contactToUserMap = new Map<Id, User>();
        for (User u : [SELECT Id, ContactId FROM User WHERE ContactId IN :contactIds]) {
            contactToUserMap.put(u.ContactId, u);
        }
        
        List<String> keyOrder = new List<String>{
            'AgencyId',
                'AgentSFId',
                'AgentName',
                'AllowAdditionalSlots',
                'AdditionalSlotsCount',
                'Username'
                };
                    
                    MuleSoftSetting__mdt mulesoftAPI = Utilities.getMuleSoftDetails('agentAdditionalAppointmentSlot');
        Organization org = Utilities.getOrganizationDetails();
        String endPointURL = org.IsSandbox ? mulesoftAPI.SandboxURL__c : mulesoftAPI.ProductionURL__c;
        
        Http http = new Http();
        
        for (Contact con : contactMap.values()) {
            if (String.isBlank(con.Account.AppointmentSystemID__c)) {
                continue;
            }
            
            User linkedUser = contactToUserMap.get(con.Id);
            if (linkedUser == null) {
               
                continue;
            }
            
            Map<String, Object> record = new Map<String, Object>();
            record.put('AgencyId', con.Account.AppointmentSystemID__c);
            record.put('AgentSFId', linkedUser.Id); 
            record.put('AgentName', con.Name);
            record.put('AllowAdditionalSlots', con.AllowAdditionalAppointmentSlots__c);
            record.put('AdditionalSlotsCount', con.AdditionalAppointmentSlots__c);
            record.put('Username', con.LastModifiedBy.Email);
            
            String orderedJson = '{';
            for (Integer i = 0; i < keyOrder.size(); i++) {
                String key = keyOrder[i];
                String valStr = JSON.serialize(record.get(key));
                orderedJson += '"' + key + '": ' + valStr;
                if (i < keyOrder.size() - 1) orderedJson += ', ';
            }
            orderedJson += '}';
            
           
            
            HttpRequest request = new HttpRequest();
            request.setHeader('Content-Type', 'application/json');
            
            if (mulesoftAPI.APIId__c == Label.AppointmentSystemKEY) {
                request.setHeader(mulesoftAPI.APIId__c, mulesoftAPI.APIKey__c);
            } else {
                request.setHeader('client_secret', mulesoftAPI.APIKey__c);
                request.setHeader('client_id', mulesoftAPI.APIId__c);
            }
            
            request.setTimeout(60000);
            request.setEndpoint(endPointURL);
            request.setMethod('POST');
            request.setBody(orderedJson);
            
            HttpResponse response;
            try {
                response = http.send(request);
              
            } catch (Exception e) {
                
            }
        }
        
       
    }
    
}