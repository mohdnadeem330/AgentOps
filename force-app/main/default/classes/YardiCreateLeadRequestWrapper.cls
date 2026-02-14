public with sharing class YardiCreateLeadRequestWrapper {

    String External_Reference='';
    String Lead_Name='';    
    Date Lead_Date;
    String Source='';
    String Primary_Property='';
    Integer Desired_Area_From=0;
    Integer Desired_Area_To=0;
    Integer Desired_Rent_From=0;
    Integer Desired_Rent_To=0;
    String Last_Name='';
    String First_Name='';
    String Email_ID='';
    String Country='';
    String MobileNo='';
    String UnitType='';
    String Company='';
    String Contact_Method='';
    String Contact_Time='';
    String Referred_By='';
    String Enquiry_Category='';
    String Enquiry_Trigger='';
    String Sales_Type='';
    String Property_Usage='';
    String Buy_Rent='';

    public YardiCreateLeadRequestWrapper(Lead leadRec) { 
        this.External_Reference=leadRec.LeadNumber__c;
        this.Lead_Name=leadRec.FirstName + (String.isNotBlank(leadRec.MiddleName) ? ' ' +leadRec.MiddleName : '') + ' '+ leadRec.lastName;   
        this.Lead_Date= date.newinstance(leadRec.CreatedDate.year(), leadRec.CreatedDate.month(), leadRec.CreatedDate.day());
        this.Source=leadRec.LeadSource;
        this.Primary_Property=leadRec.Project__c;
        this.Last_Name=leadRec.LastName;
        this.First_Name=leadRec.FirstName;
        this.Email_ID=leadRec.Email;
        this.Country=leadRec.Country != null ? leadRec.Country : '';
        this.MobileNo=leadRec.MobilePhone; //mobile number
        this.Company=leadRec.Company != null ? leadRec.Company : '';
        this.Contact_Method=leadRec.LeadSource;
        this.Contact_Time='';
        this.Referred_By='';
        this.Enquiry_Category=leadRec.EnquiryCategory__c;
        this.Enquiry_Trigger=leadRec.EnquiryTrigger__c;
        this.Sales_Type=leadRec.SalesType__c;
        this.Property_Usage=leadRec.PropertyUsage__c;
        this.Buy_Rent=leadRec.BuyRent__c;

        String invalidNumbers = '[^0-9]';  
        String area = leadRec.AreaSqmt__c != null ? leadRec.AreaSqmt__c.replace('–','-') : null;

        this.Desired_Area_From = area != null ? Integer.valueOf(area.split('-')[0].replaceAll( invalidNumbers,'')) : 0;
        this.Desired_Area_To=0;

        if(area != null && area.split('-').size() > 1){
            this.Desired_Area_To = Integer.valueOf(area.split('-')[1].replaceAll( invalidNumbers,''));
        }

        String budget = leadRec.CustomerBudget__c != null ? leadRec.CustomerBudget__c.replace('–','-') : null;

        if(leadRec.CustomerBudget__c != null){
            if(budget.contains('K')){
                budget = budget.replace('K','000');
    
            } else if(budget.contains('M') || budget.contains('Million')){
                budget = budget.replace('Million','000000');
                budget = budget.replace('M','000000');
            }
        }
        
        this.Desired_Rent_From = leadRec.CustomerBudget__c != null ? Integer.valueOf(budget.split('-')[0].replaceAll( invalidNumbers,'')) : 0;
        Desired_Rent_To = 0;

        if(leadRec.CustomerBudget__c != null && budget.split('-').size() > 1){
            Desired_Rent_To = Integer.valueOf(budget.split('-')[1].replaceAll( invalidNumbers,''));
        }

        Constant__mdt unitTypemapping = Utilities.getConstant(Constants.YARDI_UNITTYPE_MAPPING);
        Map<String,String> unitTypeMap = (Map<String,String>)JSON.deserialize(unitTypemapping.ConstantValueLong__c, Map<String,String>.class);

        this.UnitType = leadRec.UnitType__c != null ? unitTypeMap.get(leadRec.UnitType__c) : '';

    }
}