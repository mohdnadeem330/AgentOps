/**Author: Saravana Sekar
 * Created on : 17-03-2023
 * Objective - Reuseable class. NO DML.
 * It is used as WRAPPER CLASS
 */

public class ALD_FSetFormFields {
    
    public ALD_FSetFormFields(Schema.FieldSetMember f) {
        this.IsRequired = f.DBRequired;
        this.APIName = f.fieldPath;
        this.Label = f.label;
        this.Required = f.required;
        this.APIClassName = f.fieldPath.replace('__c','_xx_class');
        this.Type = String.valueOf(f.getType());
    }
    
    public ALD_FSetFormFields(Boolean required) {
        this.IsRequired = required;
    }
    
    @AuraEnabled
    public Boolean IsRequired { get;set; }
    @AuraEnabled
    public Boolean IsDisabled { get;set; }
    @AuraEnabled
    public String APIName { get;set; }  
    @AuraEnabled
    public String APIClassName { get;set; }
    @AuraEnabled
    public String Label { get;set; }    
    @AuraEnabled
    public Boolean Required { get;set; } 
    @AuraEnabled
    public String Type { get; set; }
}