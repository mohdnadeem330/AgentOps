import { LightningElement, api, wire, track } from 'lwc';
import { createRecord, getRecord, updateRecord } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValuesByRecordType, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getListUi } from 'lightning/uiListApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//import scriptresource from "@salesforce/resourceUrl/casefile";
import { NavigationMixin } from 'lightning/navigation';
import CASE_OBJECT from '@salesforce/schema/Case';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import Customer_TYPE from '@salesforce/schema/Case.CustomerType__c';
import CASE_CATEGORY from '@salesforce/schema/Case.CaseCategory__c';
import CASE_SUB_CATEGORY from '@salesforce/schema/Case.SubCategory__c';
import UNIT from '@salesforce/schema/Case.Unit__c';
import ACCOUNT_ID from '@salesforce/schema/Case.AccountId';
import SuppliedPhone from '@salesforce/schema/Case.SuppliedPhone';
import SuppliedName from '@salesforce/schema/Case.SuppliedName';
import SuppliedEmail from '@salesforce/schema/Case.SuppliedEmail';
import ContactId from '@salesforce/schema/Case.ContactId';
import Subject from '@salesforce/schema/Case.Subject';
import Description from '@salesforce/schema/Case.CaseComments__c';
import status from '@salesforce/schema/Case.Status';
import Substatus from '@salesforce/schema/Case.Sub_Status__c';
import IsScreenCase from '@salesforce/schema/Case.IsScreenCase__c';
import RecordTypeId from '@salesforce/schema/Case.RecordTypeId';
import RecordTypeName from '@salesforce/schema/Case.Recordtype_Name__c';
import CaseOrigin from '@salesforce/schema/Case.Origin';
import isFCR from '@salesforce/schema/Case.FCR__c';
import getAccountid from '@salesforce/apex/ManageCasesController.getAccountid';
import LightningConfirm from 'lightning/confirm';
import checkDuplicate from '@salesforce/apex/CaseService.checkDuplicate';
import accountNameLabel from '@salesforce/label/c.Visitor_Account';


export default class cloneCase extends NavigationMixin(LightningElement) {

    CustomerTypeValue
    SubVerticleValue
    CaseCategoryValue
    SubStatusValue
    SubjectValue
    CaseOriginValue
    CaseCommentsValue
    @track UnitValue
    selectedOption
    @track AccountValue
    AccountValueInput
    UnitValueInput
    ContactValue
    SubCatValue
    pickSubCatValue
    pickContactValues
    isFCR = false
    isFcrDisabled 
    pickCustomerType;
    pickCustomerTypeAll;

    pickSubStatus;
    pickSubVerticle;
    pickCaseOrigin
    pickCaseCategory
    pickSubController
    pickcategoryController
    pickValUnit = []
    pickValAccount = []
    pickAccountValueInput = []
    pickUnitValueInput = []
    fieldlabel = "CaseCategory__c";
    objectname = "Case";
    displayname = "Case Category";
    selectedvalue = '';
    Subrequired = true;
    CaseUnit = UNIT
    AccountId = ACCOUNT_ID
    showRadioButtons = true;
    showFields = true;
    selectedOption = '';
    newRecordTypeId = '';
    recordTypeId = '';
    recordTypeIds;
    @api recordId;
    @api objectApiName;
    tenantfields = false;
    showvisitorfield = false;
    preOriginValue;
    TenantNameVal
    TenantEmailVal
    TenantPhoneVal
    VisitorNameVal
    VisitorEmailVal
    VisitorPhoneVal
    @track caseDetails = []
    ShowAccountSearch = true
    ShowUnitSearch = true
    objectName;
    customeTypeFieldsDisabled;
    isLoading = false;
    readonlycustomerType = false
    readonlyTenant = false
    readonlyVisitor = false
    Disabledfields = false
    TenantReadOnly = false;
    VisitorReadOnly = false;
    VisitorReadOnlyMobile = false;
    showError = false;

    connectedCallback() {
           
       
    }

    

    get options() {
        return [
            { label: 'Queries', value: 'Queries' },
            { label: 'Request', value: 'Requests' },
            { label: 'Complaint', value: 'Complaints' },
        ];
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [Customer_TYPE, CASE_CATEGORY, CASE_SUB_CATEGORY, UNIT, ACCOUNT_ID, SuppliedPhone, SuppliedName, SuppliedEmail, ContactId, Subject, Description, CaseOrigin, isFCR, RecordTypeId, RecordTypeName, status, Substatus]
    })
    caseDetail({ data, error }) {
        if (data) {
           
            this.caseDetails = data;
            this.selectedOption = data.fields.Recordtype_Name__c.value;
            this.recordTypeId = data.fields.RecordTypeId.value;
            this.objectrecordtypeid = data.fields.RecordTypeId.value;
           

        }
    }



    loaddata(datavalue) {
        this.preOriginValue = datavalue.fields.Origin.value;
        this.CaseOriginValue = datavalue.fields.Origin.value;
        this.CustomerTypeValue = datavalue.fields.CustomerType__c.value;
        this.isFCR = datavalue.fields.FCR__c.value;
        this.Disabledfields =true;
        
        if (this.selectedOption == 'Queries') {
            this.isFCR = true;
            this.isFcrDisabled = true;
        } else if (this.selectedOption == 'Complaints') {
            
            this.isFcrDisabled = true;
            this.isFCR = false;
        } else {
            this.isFcrDisabled = false;
            this.isFCR = datavalue.fields.FCR__c.value;
        }

        if(this.CaseOriginValue == 'Customer Portal')
        {
            this.CaseOriginValue = null;
            this.pickCustomerType = this.pickCustomerTypeAll.filter(val => ['Owner', 'Tenant'].includes(val.value));
        }

        if(this.CustomerTypeValue == 'Owner')
        {
            this.customeTypeFieldsDisabled= false;
            this.pickCustomerType = this.pickCustomerTypeAll.filter(val => ['Owner', 'Tenant'].includes(val.value));
        } else if (this.CustomerTypeValue == 'Tenant') {
            this.tenantfields = true;
            this.TenantEmailVal = datavalue.fields.SuppliedEmail.value;
            this.TenantNameVal = datavalue.fields.SuppliedName.value;
            this.TenantPhoneVal = datavalue.fields.SuppliedPhone.value;
            this.customeTypeFieldsDisabled= false;
            this.pickCustomerType = this.pickCustomerTypeAll.filter(val => ['Owner', 'Tenant'].includes(val.value));
        } else if (this.CustomerTypeValue == 'Visitor') {
            this.showvisitorfield = true;
            this.customeTypeFieldsDisabled= true;
            this.VisitorEmailVal = datavalue.fields.SuppliedEmail.value;
            this.VisitorNameVal = datavalue.fields.SuppliedName.value;
            this.VisitorPhoneVal = datavalue.fields.SuppliedPhone.value;
          
        }
      

        this.CaseCategoryValue = datavalue.fields.CaseCategory__c.value;       
        this.SubjectValue = datavalue.fields.Subject.value;
        this.CaseCommentsValue = datavalue.fields.CaseComments__c.value;
      
      
        let key = this.pickSubController.controllerValues[this.CaseCategoryValue];
        this.pickSubCatValue = this.pickSubController.values.filter(opt => opt.validFor.includes(key));
        this.SubCatValue = datavalue.fields.SubCategory__c.value;

        if (datavalue.fields.AccountId.value) {
          
            this.AccountValue = datavalue.fields.AccountId.value;
            getAccountid({ UnitId: null, AccountId: this.AccountValue })
                .then(data => {
                    if (data.Contactlist != null) {
                        this.pickContactValues = data.Contactlist.map(con => {
                            return {
                                label: con.Name,
                                value: con.Id
                            };
                        });
                        if (data.AccounType == 'Person') {
                            this.ContactValue = data.Contactlist[0].Id;
                        }
                        else
                        {
                            this.ContactValue = datavalue.fields.ContactId.value
                        }
                    }
                   
                })
                .catch(error => {
                    
                })
        }
        else
        {
            this.Disabledfields =false;
        }


        if (datavalue.fields.Unit__c.value) {
           
            this.UnitValue = datavalue.fields.Unit__c.value;
        }
        else
        {
            this.Disabledfields =false;
        }

    }

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    accountMetadata({ data, error }) {
        if (data) {
            this.recordTypeIds = data.recordTypeInfos;
           
        } else if (error) {
            this.showToast('Error', 'Error fetching record type information: ' + error.body.message, 'error');
        }
    }

    @wire(getPicklistValuesByRecordType, {
        recordTypeId: '$recordTypeId',
        objectApiName: CASE_OBJECT
    })
    wiredRecordTypeInfo({ data, error }) {
        if (data) {
          
            this.pickCustomerTypeAll = data.picklistFieldValues.CustomerType__c.values;
            this.pickCustomerType = this.pickCustomerTypeAll.filter(val => ['Owner', 'Tenant', 'Visitor'].includes(val.value)
            )
            this.pickCaseCategory = data.picklistFieldValues.CaseCategory__c.values;
                  
            this.caseDetails.fields.Status.value;
            this.pickSubController = data.picklistFieldValues.SubCategory__c;           
           
           
            this.pickCaseOrigin = data.picklistFieldValues.Origin.values;
            this.pickCaseOrigin = data.picklistFieldValues.Origin.values.filter(item => {
                return ['Phone', 'Whatsapp', 'Walk-In'].includes(item.value);
            });
           
            if (this.caseDetails) {
                this.loaddata(this.caseDetails)
               
            }

        }
        if (error) {
           
        }
    }

    @wire(getListUi, { objectApiName: ACCOUNT_OBJECT, listViewApiName: 'AllAccounts' })
    wiredAccountList({ error, data }) {
        if (data) {
            this.AccountList = data.records.records;
            this.pickValAccount = this.AccountList.map(account => ({
                label: account.fields.Name.value,
                value: account.id
            }));
        } else if (error) {
            console.error('Error fetching account data:', error);
        }
    }


    handleRadioChange(event) {
        this.selectedOption = event.detail.value;
       
        if (this.recordTypeIds) {
            this.recordTypeId = Object.keys(this.recordTypeIds).find(recordTypeId => this.recordTypeIds[recordTypeId].name === this.selectedOption);
          
}
     
    }

    async handleCreateClick() {       
             
             checkDuplicate({
                unitValue: this.UnitValueInput != null ? this.UnitValueInput : this.UnitValue,
                categoryValue: this.CaseCategoryValue,
                subCategoryValue: this.SubCatValue
            })
                .then(isDuplicate => {

                    if (isDuplicate.length > 0) {
                        if (this.CustomerTypeValue == 'Visitor') {
                           
                            if (this.AccountValue == accountNameLabel) {
                              
                               
                                this.ContactValue = null;
                                this.UnitValue = null;
                               
                                this.handleCreate(true);
                            }
                            else {
                                this.showToast('Error', 'Please select test visitor account for visitor customer type.', 'error');
                            }
                        }
                        else {
                            this.showToast('Error', 'Duplicate case found with same Unit, Case Category & Case Sub Category.', 'error');

                        }
                    }
                    else {
                        if (this.CustomerTypeValue == 'Visitor') {
                           
                            if (this.AccountValue == accountNameLabel) {
                               
                                this.ContactValue = null;
                                this.UnitValue = null;
                              
                                this.handleCreate(true);
                            }
                            else {
                                this.showToast('Error', 'Please select test Visitor account for visitor customer type.', 'error');
                            }

                        } else {
                          
                            this.handleCreate(false);

                        }
                    }
                })
                .catch(error => {
                  
                });
        }
   // }

    resetproperties() {
       
        this.CaseCommentsValue = null;       
        this.TenantEmailVal = null;
        this.pickAccountValueInput = null;       
        this.pickUnitValueInput = null;
        this.TenantNameVal = null;
        this.TenantPhoneVal = null;
        this.VisitorEmailVal = null;
        this.VisitorNameVal = null;
        this.VisitorPhoneVal = null;      

    }

    handleChange(event) {
        let name = event.target.name;
        let val = event.target.value;

        if (name === 'CustomerType') {
            this.CustomerTypeValue = val;          
            if (val == 'Tenant') {
                this.tenantfields = true;
                this.showvisitorfield = false;
                this.TenantReadOnly = true;
                this.VisitorReadOnly = false;
                this.VisitorReadOnlyMobile = false;
            
                this.resetproperties();
            }
            if (val == 'Visitor') {
                this.showvisitorfield = true;
                this.tenantfields = false;
                this.VisitorReadOnly = true;
                this.VisitorReadOnlyMobile = true;
                this.TenantReadOnly = false;
                this.AccountValue = accountNameLabel;
        
                this.resetproperties();
            }
            if (val == 'Owner') {
                this.showvisitorfield = false;
                this.tenantfields = false;
                this.resetproperties();
                this.TenantReadOnly = false;
                this.VisitorReadOnly = false;
                this.VisitorReadOnlyMobile = false;
           
            }
        } else if (name === 'SubVerticle') {
            this.SubVerticleValue = val;
        } else if (name === 'CaseCategory') {
            this.CaseCategoryValue = val;
            this.selectedvalue = val;
            let key = this.pickSubController.controllerValues[event.target.value];
            this.pickSubCatValue = this.pickSubController.values.filter(opt => opt.validFor.includes(key));

        } else if (name === 'CaseSubStatus') {
            this.SubStatusValue = val;
        }
        else if (name === 'CasePriority') {
            this.priorityValue = val;
        }
        else if (name === 'TenantName') {
            this.TenantNameVal = val;
        }
        else if (name === 'TenantEmail') {
            this.TenantEmailVal = val;
        }
        else if (name === 'TenantPhone') {
            this.TenantPhoneVal = val;
        }
        else if (name === 'VisitorName') {
            this.VisitorNameVal = val;
        }
        else if (name === 'VisitorEmail') {
            this.VisitorEmailVal = val;
        }
        else if (name === 'VisitorPhone') {
            this.VisitorPhoneVal = val;
        }
        else if (name === 'InputUnit') {
            this.UnitValueInput = val;
            this.UnitValue = null;
        }
        else if (name === 'Account') {
            this.AccountValueInput = val;
            this.AccountValue = null;
        }
        else if (name === 'Contact') {
            this.ContactValue = val;
        }
        else if (name === 'Subject') {
            this.SubjectValue = val;
        }
        else if (name === 'CaseComments') {
            this.CaseCommentsValue = val;
        }
        else if (name === 'isFCR') {
            
            this.isFCR = event.target.checked;
        }
        else if (name === 'CaseOrigin') {

            this.VisitorReadOnlyMobile = true;
            this.CaseOriginValue = val;
        }
        else if (name === 'CaseSubCategory') {
            this.SubCatValue = val;
        }
        if (this.CaseOriginValue == 'Email' && this.CustomerTypeValue == 'Visitor') {
            this.VisitorReadOnlyMobile = false;
        }
    }

    @track selectedPicklistValue;
    handlePicklistSelect(event) {

        const { value, label } = event.detail;
        this.selectedPicklistValue = value;
        this.CaseCategoryValue = this.selectedPicklistValue;
        let key = this.pickSubController.controllerValues[event.target.value];
        this.pickSubCatValue = this.pickSubController.values.filter(opt => opt.validFor.includes(key));
      
        let selectedKey = this.pickSubController.controllerValues[value];
        this.pickSubCatValue = this.pickSubController.values.filter(opt => opt.validFor.includes(selectedKey));
    }

    handleUnitChange(event) {

        let val = event.detail.recordId;
        this.UnitValue = this.dlpUnitId != null ? this.dlpUnitId : val;

        this.UnitValueInput = null;

        if (val != null) {
            getAccountid({ UnitId: val, AccountId: null })
                .then(data => {
                    if (data.AccountVal != null) {
                        this.pickAccountValueInput = data.AccountList.map(account => {
                            return {
                                label: account.Name,
                                value: account.Id
                            };
                        });
                        this.AccountValueInput = data.AccountVal;
                        this.ShowAccountSearch = false;
                    }
                    if (data.Contactlist != null) {
                        this.pickContactValues = data.Contactlist.map(con => {
                            return {
                                label: con.Name,
                                value: con.Id
                            };
                        });
                       

                        if (data.AccounType == "Person") {
                          
                            this.ContactValue = data.Contactlist[0].Id;

                        }

                    }
                   
                })
                .catch(error => {
                    
                })
        }
        else {
            this.ShowAccountSearch = true;
            this.pickContactValues = null;
            this.AccountValue = null;
            this.AccountValueInput = null;
            this.ContactValue = null;
        }

    }

    handleAccountChange(event) {

        let val = event.detail.recordId;
        this.AccountValue = this.dlpAccountId != null ? this.dlpAccountId : val;
        // if (this.dlpAccountId == null) {
        //     this.ContactValue = null;
        // }
        this.pickContactValues = null;
        this.AccountValueInput = null;
        this.ShowUnitSearch = true;
        if (val != null) {
            getAccountid({ UnitId: null, AccountId: val })
                .then(data => {
                    this.ShowUnitSearch = false;
                    if (data.UnitList != null) {
                        this.pickUnitValueInput = data.UnitList.map(unit => {
                            return {
                                label: unit.Name,
                                value: unit.Id
                            };
                        });

                    }
                    if (data.Contactlist != null) {
                        this.pickContactValues = data.Contactlist.map(con => {
                            return {
                                label: con.Name,
                                value: con.Id
                            };
                        });
                        if (data.AccounType == 'Person') {
                            this.ContactValue = data.Contactlist[0].Id;
                        }

                    }
                   
                })
                .catch(error => {
                   
                })
        }
    }

  

    handleCreate(isVisitor) {

        const fields = {};
        this.isLoading = true;
        const phoneRegex = /^[0-9]{7,15}$/;
        const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
        fields[Customer_TYPE.fieldApiName] = this.CustomerTypeValue;
        fields[CASE_CATEGORY.fieldApiName] = this.CaseCategoryValue;
      
        fields[Description.fieldApiName] = this.CaseCommentsValue;
       
        if (isVisitor == false) {
            fields[UNIT.fieldApiName] = this.UnitValueInput != null ? this.UnitValueInput : this.UnitValue;
           
        }
        else {
            fields[UNIT.fieldApiName] = null;
           
        }
        
        fields[ACCOUNT_ID.fieldApiName] = this.AccountValueInput != null ? this.AccountValueInput : this.AccountValue;
        fields[ContactId.fieldApiName] = this.ContactValue;
        fields[SuppliedEmail.fieldApiName] = this.TenantEmailVal != null ? this.TenantEmailVal : this.VisitorEmailVal;
        fields[SuppliedName.fieldApiName] = this.TenantNameVal != null ? this.TenantNameVal : this.VisitorNameVal;
        fields[SuppliedPhone.fieldApiName] = this.TenantPhoneVal != null ? this.TenantPhoneVal : this.VisitorPhoneVal;
        fields[RecordTypeId.fieldApiName] = this.recordTypeId;
        fields[CaseOrigin.fieldApiName] = this.CaseOriginValue;
        fields[IsScreenCase.fieldApiName] = true;
        fields[isFCR.fieldApiName] = this.isFCR;
        fields[CASE_SUB_CATEGORY.fieldApiName] = this.SubCatValue;

      

        if (this.selectedOption == null) {
            this.showToast('Error', 'Please select Case Type!', 'error');
            return;
        }

        if (this.CustomerTypeValue == null) {
            this.showToast('Error', 'Please select Customer Type!', 'error');
            return;
        }
        if (this.CaseOriginValue == null) {
            this.showToast('Error', 'Please select Case Origin!', 'error');
            return;
        }
        else if (this.CaseCategoryValue == null) {
            this.showToast('Error', 'Please select Case Category!', 'error');
            return;
        }

        if (this.SubCatValue == null) {
            this.showToast('Error', 'Please select Sub Case Category!', 'error'); //Raj
            return;
        }
        if (fields[ACCOUNT_ID.fieldApiName] == null) {
            this.showToast('Error', 'Please select Account!', 'error');
            return;
        }
        if (fields[UNIT.fieldApiName] == null && isVisitor == false) {
            this.showToast('Error', 'Please select Unit!', 'error');
            return;
        }
       
        if (this.ContactValue == null && isVisitor == false) {
           
            this.showToast('Error', 'Please select Contact!', 'error');
            return;
        }

        if (this.CustomerTypeValue == 'Tenant' && this.TenantPhoneVal != null) {
            if (!phoneRegex.test(this.TenantPhoneVal)) {
                this.showToast('Error', 'Please enter a valid Phone Number', 'error');
                return;
            }
        }
        if (this.CustomerTypeValue == 'Visitor' && this.VisitorPhoneVal != null) {
            if (!phoneRegex.test(this.VisitorPhoneVal)) {
                this.showToast('Error', 'Please enter a valid Phone Number', 'error');
                return;
            }
        }
        if (this.CustomerTypeValue == 'Tenant' && this.TenantEmailVal != null) {
            if (!emailRegex.test(this.TenantEmailVal)) {
                this.showToast('Error', 'Please enter a valid Email', 'error');
                return;
            }
        }
        if (this.CustomerTypeValue == 'Visitor' && this.VisitorEmailVal != null) {
            if (!emailRegex.test(this.VisitorEmailVal)) {
                this.showToast('Error', 'Please enter a valid Email', 'error');
                return;
            }
        }
        if(this.CaseCommentsValue == null || this.CaseCommentsValue =='')
            {
                this.showToast('Error', 'Please enter Comment', 'error');
                return;
            }
        if ((this.CustomerTypeValue == 'Tenant' && (fields[SuppliedEmail.fieldApiName] == null ||fields[SuppliedEmail.fieldApiName] == '')) ||
            (this.CustomerTypeValue == 'Tenant' && (fields[SuppliedName.fieldApiName] == null || fields[SuppliedName.fieldApiName] == '')  ) ||
            (this.CustomerTypeValue == 'Tenant' && (fields[SuppliedPhone.fieldApiName] == null || fields[SuppliedPhone.fieldApiName] == ''))) {
            this.showToast('Error', 'Please Enter Tenant Name/Email/Phone. ', 'error');
            return;
        }

        if ((this.CustomerTypeValue == 'Visitor' && (fields[SuppliedEmail.fieldApiName] == null || fields[SuppliedEmail.fieldApiName] == '')) ||
            (this.CustomerTypeValue == 'Visitor' && (fields[SuppliedName.fieldApiName] == null || fields[SuppliedName.fieldApiName] == '')) ||
            (this.CustomerTypeValue == 'Visitor' && (fields[SuppliedPhone.fieldApiName] == null || fields[SuppliedName.fieldApiName] == ''))) {
            this.showToast('Error', 'Please Enter Visitor Name/Email/Phone. ', 'error');
            return;
        }

        const caseRecord = { apiName: CASE_OBJECT.objectApiName, fields: fields };
        createRecord(caseRecord)
            .then(result => {
                this.isLoading = false;
                this.showToast('Success', 'Case created successfully!', 'success');
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result.id,
                        objectApiName: 'Case',
                        actionName: 'view'
                    }
                });
                if (this.dlpUnitId != null) {
                    //  this.closeTab();
                }
            })
            .catch(error => {
                if (error) {                   
                    this.isLoading = false;                  
                    this.handleError(error);
                }
            });
    }




showToast(title, message, variant) {
   
    this.isLoading = false;
    const event = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant,
    });
    this.dispatchEvent(event);

}

handleError(error) {
    let fieldErrors = [];
    if (error.body && error.body.output && JSON.stringify(error.body.output.fieldErrors) !== '{}') {
        fieldErrors = Object.values(error.body.output.fieldErrors).flat();
        this.errorMessages = fieldErrors.map(err => err.message);
       
    } else if (error.body && error.body.output && JSON.stringify(error.body.output.errors !== '{}')) {
        fieldErrors = Object.values(error.body.output.errors).flat();
        this.errorMessages = fieldErrors.map(err => err.message);
        
    }

    this.ShowMessageValue = this.errorMessages;
  
    this.showToast('Error', JSON.stringify(this.errorMessages), 'error');
}



}