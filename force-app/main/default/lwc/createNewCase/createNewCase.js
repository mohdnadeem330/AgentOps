import { LightningElement, api, wire, track } from 'lwc';
import { createRecord, getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValuesByRecordType, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getListUi } from 'lightning/uiListApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript, loadStyle } from "lightning/platformResourceLoader";
//import scriptresource from "@salesforce/resourceUrl/casefile";
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import CASE_OBJECT from '@salesforce/schema/Case';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import checkDuplicate from '@salesforce/apex/CaseService.checkDuplicate';
import Customer_TYPE from '@salesforce/schema/Case.CustomerType__c';
import CASE_CATEGORY from '@salesforce/schema/Case.CaseCategory__c';
import CASE_SUB_CATEGORY from '@salesforce/schema/Case.SubCategory__c';
import UNIT from '@salesforce/schema/Case.Unit__c';
import ACCOUNT_ID from '@salesforce/schema/Case.AccountId';
import SuppliedPhone from '@salesforce/schema/Case.SuppliedPhone';
import SuppliedName from '@salesforce/schema/Case.SuppliedName';
import SuppliedEmail from '@salesforce/schema/Case.SuppliedEmail';
import ContactId from '@salesforce/schema/Case.ContactId';
//import Subject from '@salesforce/schema/Case.Subject';
import Location from '@salesforce/schema/Case.Location__c';
import IsScreenCase from '@salesforce/schema/Case.IsScreenCase__c';
import Description from '@salesforce/schema/Case.CaseComments__c';
import RecordTypeId from '@salesforce/schema/Case.RecordTypeId';
import CaseOrigin from '@salesforce/schema/Case.Origin';
import isFCR from '@salesforce/schema/Case.FCR__c';
import getAccountid from '@salesforce/apex/ManageCasesController.getAccountid';
import { IsConsoleNavigation, getFocusedTabInfo, closeTab } from 'lightning/platformWorkspaceApi';

export default class CreateNewCase extends NavigationMixin(LightningElement) {
    CustomerTypeValue
    SubVerticleValue
    CaseCategoryValue
    SubjectValue
    CaseOriginValue =''
    CaseCommentsValue
    LocationValue
    @track UnitValue
    selectedOption
    @track AccountValue
    AccountValueInput
    UnitValueInput
    ContactValue
    SubCatValue
    pickSubCatValue
    picklocationValue
    pickContactValues
    isFCR = false
    pickCustomerType;
    pickSubVerticle;
    pickCaseOrigin
    pickCaseCategory
    pickSubController
    pickcategoryController
    pickValUnit = []
    pickValAccount = []
    pickAccountValueInput = []
    pickUnitValueInput = []

    Subrequired = false;
    CaseUnit = UNIT
    AccountId = ACCOUNT_ID
    showRadioButtons = false;
    showFields = true;
    selectedOption = '';
    recordTypeId = '';
    recordTypeIds;
    @api recordId;
    @api objectApiName;
    ShowLocation = false;
    tenantfields = false;
    showvisitorfield = false;

    TenantNameVal
    TenantEmailVal
    TenantPhoneVal
    VisitorNameVal
    VisitorEmailVal
    VisitorPhoneVal

    ShowAccountSearch = true
    ShowUnitSearch = true
    objectName;
    isLoading = false;
    readonlycustomerType = false
    readonlyTenant = false
    readonlyVisitor = false
    Disabledfields = true
    FcrDisabled =true;
    isfcrdisabled = true;
    AccountDisabled =true;
    UnitDisabled =true;
    ContactDisabled =true;
    SubCategoryDisabled =true;
    CaseCategoryDisabled =true;
    TenantReadOnly = false;
    VisitorReadOnly = false;
    showError = false;
    fieldlabel = "CaseCategory__c";
    objectname = "Case";
    displayname = "Case Category";
    ispicklistdisabled = true;
    tempFlag;
    customerTypeStatus;
    customerTypeDisabled;
    pickCustomerRecord;
    checkJointAccount = false;

    connectedCallback() {}

    handlePopState(event) {       // Handle the back/forward navigation
              
        window.location.reload();
       }

   currentPageReference;
    @api dlpUnitId;
    @api dlpAccountId;   
    
    @wire(CurrentPageReference)
    getCurrentPageReference(currentPageReference) {
       
        this.currentPageReference = currentPageReference;
        new Promise(
            (resolve, reject) => {
            setTimeout(() => {
                if(this.currentPageReference){
                    this.dlpAccountId = this.currentPageReference.state.c__AccountId;                  
                    this.AccountValue=this.currentPageReference.state.c__AccountId;                   
                    this.customerTypeStatus = this.currentPageReference.state.c__CustomerType;
                    this.Disabledfields = false;
                    this.pickCustomerType =null;
                    this.customerTypeValue =null;
                    
                 
                    if(this.customerTypeStatus ==='Visitor')
                    {              
                        this.customerTypeValue ='Visitor';                        
                        this.dlpUnitId = this.currentPageReference.state.c__UnitId;
                        this.unitValue=this.currentPageReference.state.c__UnitId;                       
                        this.VisitorReadOnly = true;
                        this.unitValue =null;
                        this.UnitValueInput =null;                        
                        this.dlpUnitId = null;
                        this.tenantfields = false;
                        this.ContactValue=null;
                        this.AccountDisabled =true;
                        this.ContactDisabled =true;
                        this.UnitDisabled =true;
                        this.showvisitorfield = true;
                        this.Disabledfields =false;
                        this.CaseCategoryDisabled =false;
                        this.SubCategoryDisabled =false;  
                        this.ispicklistdisabled = false;  
                        this.Subrequired =true;                         
                                     
                    }
                    else if (this.customerTypeStatus ==='Others'){
                        this.customerTypeValue ='Others';                        
                        this.dlpUnitId = this.currentPageReference.state.c__UnitId;
                        this.unitValue=this.currentPageReference.state.c__UnitId;                       
                        this.VisitorReadOnly = true;
                        this.unitValue =null;
                        this.UnitValueInput =null;                        
                        this.dlpUnitId = null;
                        this.tenantfields = false;
                        this.ContactValue=null;
                        this.AccountDisabled =true;
                        this.ContactDisabled =false;
                        this.UnitDisabled =true;
                        this.showvisitorfield = false;
                        this.Disabledfields =false;
                        this.CaseCategoryDisabled =false;
                        this.SubCategoryDisabled =false;  
                        this.ispicklistdisabled = false;  
                        this.Subrequired =true;
                        this.getUnitDeatils();

                    }
                    else
                    { 
                        this.dlpUnitId = this.currentPageReference.state.c__UnitId;
                        this.unitValue=this.currentPageReference.state.c__UnitId;
                        console.log('this.unitValue'+this.unitValue);
                        this.showvisitorfield = false;
                        this.checkJointAccount=this.currentPageReference.state.c__checkJointAccount;
                    //  console.log('this.checkJointAccount'+this.checkJointAccount);
                        if(this.checkJointAccount == 'true')
                        {
                            console.log('Enabled');
                            this.AccountDisabled =false;
                            this.ContactDisabled =false;
                            this.UnitDisabled =false;
                        }                        
                        else if(this.checkJointAccount == 'false')
                        {
                            console.log('disabled');
                            this.AccountDisabled =true;
                            this.ContactDisabled =false;
                            this.UnitDisabled =true;
                        }
                        else
                        {console.log('final disabled');

                        }
                        this.VisitorReadOnly = false;
                        this.getUnitDeatils();
                    }
                            
                    this.CaseOriginValue =null;
                    this.selectedOption = null;
                    this.resetproperties();                   
                    resolve();
                }
            }, 0);
            })               
            .catch((error) => {
                console.error(JSON.stringify(error));
            })
            .finally(() => {
                // disable a spinner if applicable
            });
    }


    getUnitDeatils(){
        console.log('this.dlpAccountId*********', this.dlpAccountId); 
        if (this.dlpAccountId != null) {
            this.AccountValue = this.dlpAccountId;
            getAccountid({ UnitId: null, AccountId: this.AccountValue })
                .then(data => {
                    console.log('data.Contactlist*********', JSON.stringify(data.Contactlist)); 
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
                        else if (data.AccounType == 'Org') {
                            this.ContactValue = data.Contactlist[0].Id;
                        }
                    }                  

                })
                .catch(error => {
                   
                })
        }
        if (this.dlpUnitId != null) {
           
            this.UnitValue = this.dlpUnitId
        }
    }

   

  
/*
    loadresources() {
        const styleTags = Array.from(document.querySelectorAll('link[rel="stylesheet"]'));
        styleTags.forEach(tag => {
            if (tag.href.includes(scriptresource)) {
                tag.disabled = true; // Disable the stylesheet
                tag.parentNode.removeChild(tag); // Remove the stylesheet from the DOM
            }
        });
    }
    */

    get options() {
        return [
            { label: 'Queries', value: 'Queries' },
            { label: 'Request', value: 'Requests' },
            { label: 'Complaint', value: 'Complaints' },
        ];
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
           
            if(this.customerTypeStatus ==='Visitor'){
                this.pickCustomerRecord = data.picklistFieldValues.CustomerType__c.values;
                this.pickCustomerType = this.pickCustomerRecord.filter(val => ['Visitor'].includes(val.value)
                )
                this.CustomerTypeValue ='Visitor';              
            }
            else if(this.customerTypeStatus ==='Others'){
                this.pickCustomerRecord = data.picklistFieldValues.CustomerType__c.values;
                this.pickCustomerType = this.pickCustomerRecord.filter(val => ['Others'].includes(val.value)
                )
                this.CustomerTypeValue ='Others'; 
            }
            else
            {            
                this.pickCustomerRecord = data.picklistFieldValues.CustomerType__c.values;
                this.pickCustomerType = this.pickCustomerRecord.filter(val => ['Owner', 'Tenant'].includes(val.value))
                    
            }
           
           this.picklocationValue = data.picklistFieldValues.Location__c.values;
            this.pickCaseCategory = data.picklistFieldValues.CaseCategory__c.values;
            this.pickCaseOrigin = data.picklistFieldValues.Origin.values.filter(item => {
                return ['Phone', 'Whatsapp', 'Walk-In'].includes(item.value);
            });
            if(this.CaseOriginValue ==null)
            {
                this.CaseOriginValue ='Phone';
            }
            this.pickSubController = data.picklistFieldValues.SubCategory__c;           
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
          
        }
    }

   

    handleRadioChange(event) {
       
        this.selectedOption = event.detail.value;
        
        if (this.recordTypeIds) {
            this.recordTypeId = Object.keys(this.recordTypeIds).find(recordTypeId => this.recordTypeIds[recordTypeId].name === this.selectedOption);
            this.objectrecordtypeid = this.recordTypeId;
           
        }
        if (this.selectedOption == 'Queries') {
            this.isFCR = true;
            this.FcrDisabled=true;
        } else if (this.selectedOption == 'Complaints') {
            this.isFCR = false;
            this.FcrDisabled=true;
        }else{
            this.FcrDisabled=false;
        }

    
    }

  

    resetproperties() {
        this.SubCatValue=null;
        this.pickSubCatValue =null;  
        this.CASE_SUB_CATEGORY =null;
      
        this.selectedvalue=null;
        // this.CaseCategoryValue = ''; // r-null change to ''
       // this.SubjectValue = null;
      // this.CaseOriginValue = null; // r-added
        this.CaseCommentsValue = null;
        this.caseor
       
        this.TenantEmailVal = null;
        this.pickAccountValueInput = null;
        if (this.dlpAccountId == null) {
            this.ContactValue = null;
        }
        this.pickUnitValueInput = null;
        this.TenantNameVal = null;
        this.TenantPhoneVal = null
        this.VisitorEmailVal = null
        this.VisitorNameVal = null
        this.VisitorPhoneVal = null
        //  this.AccountValue = undefined
        this.AccountValueInput = null;

    }
   

    handleChange(event) {
        

        let name = event.target.name;
        let val = event.target.value;

        if (name === 'CustomerType') {          
            this.CustomerTypeValue = val;           
          //  this.Disabledfields = false;
           // this.AccountDisabled =false;
           // this.UnitDisabled =false;
           // this.ContactDisabled =false;
            this.Subrequired = true;
            this.ispicklistdisabled = false;
            if (val == 'Tenant') {
                this.tenantfields = true;
                this.showvisitorfield = false;
                this.TenantReadOnly = true;
                this.VisitorReadOnly = false;
               // this.AccountDisabled =true;
               // this.UnitDisabled =true;
               // this.ContactDisabled =true;
                this.resetproperties();
            }
            if (val == 'Visitor') {
                this.showvisitorfield = true;
                this.tenantfields = false;
                this.VisitorReadOnly = true;
                this.TenantReadOnly = false;
              //  this.AccountDisabled =true;
               // this.UnitDisabled =true;
               // this.ContactDisabled =true;
                this.resetproperties();
            }
            if (val == 'Owner') {
                this.showvisitorfield = false;
                this.tenantfields = false;
                this.resetproperties();
                this.TenantReadOnly = false;
              //  this.VisitorReadOnly = false;
              //  this.AccountDisabled =true;
             //   this.UnitDisabled =true;
              //  this.ContactDisabled =true;
            }
        } else if (name === 'SubVerticle') {
            this.SubVerticleValue = val;
        } else if (name === 'CaseCategory') {
            this.CaseCategoryValue = val;
            if(val == 'CMO' || val == 'MEP' ||val == 'Civil' ){
                this.ShowLocation = true;
            }
            else{
                this.ShowLocation = false;
            }            
            this.selectedvalue = val;
            let key = this.pickSubController.controllerValues[event.target.value];
            this.pickSubCatValue = this.pickSubController.values.filter(opt => opt.validFor.includes(key));
            

        } else if (name === 'CasePriority') {
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
            this.CaseOriginValue = val;
        }
        else if (name === 'CaseSubCategory') {
            this.SubCatValue = val;
        } 
        else if (name === 'CaseLocation'){
            this.LocationValue = val;
        }    

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
        if (this.dlpAccountId == null) {
            this.ContactValue = null;
        }
        this.UnitValue =null;
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
                           // this.unitValue =data.UnitList[0].Id;
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
    @wire(IsConsoleNavigation) isConsoleNavigation;
        async closeTab() {
        if (!this.isConsoleNavigation) {
            return;
        }
        const { tabId } = await getFocusedTabInfo();
        await closeTab(tabId);
        }
    handleCreate() {       
        const fields = {};
        this.isLoading = true;
        const phoneRegex = /^[0-9]{7,15}$/;
        const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
        fields[Customer_TYPE.fieldApiName] = this.CustomerTypeValue;
        fields[CASE_CATEGORY.fieldApiName] = this.CaseCategoryValue;
        //fields[Subject.fieldApiName] = '--';
        fields[Description.fieldApiName] = this.CaseCommentsValue;
       
        if(this.customerTypeStatus ==='Visitor')
        {
            fields[UNIT.fieldApiName] = null;
            fields[ContactId.fieldApiName] =null;
        }
        else
        {
            console.log('this.UnitValueInput'+this.UnitValueInput);
            console.log('this.UnitValue'+this.UnitValue);
        fields[UNIT.fieldApiName] = this.UnitValueInput != null ? this.UnitValueInput : this.UnitValue;
       
        }
       
        fields[ACCOUNT_ID.fieldApiName] = this.AccountValueInput != null ? this.AccountValueInput : this.AccountValue;
        fields[ContactId.fieldApiName] = this.ContactValue;
        fields[SuppliedEmail.fieldApiName] = this.TenantEmailVal != null ? this.TenantEmailVal : this.VisitorEmailVal;
        fields[SuppliedName.fieldApiName] = this.TenantNameVal != null ? this.TenantNameVal : this.VisitorNameVal;
        fields[SuppliedPhone.fieldApiName] = this.TenantPhoneVal != null ? this.TenantPhoneVal : this.VisitorPhoneVal;
        fields[RecordTypeId.fieldApiName] = this.recordTypeId;
        fields[CaseOrigin.fieldApiName] = this.CaseOriginValue;
        fields[isFCR.fieldApiName] = this.isFCR;
        fields[CASE_SUB_CATEGORY.fieldApiName] = this.SubCatValue;
        fields[IsScreenCase.fieldApiName] = true;
        fields[Location.fieldApiName] = this.LocationValue;

       
        console.log('fields'+JSON.stringify(fields));
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
     
        if (this.CaseCategoryValue == null) {
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
        console.log('Unit value'+fields[UNIT.fieldApiName])
        if (fields[UNIT.fieldApiName] == null && this.customerTypeStatus !=='Visitor' && this.customerTypeStatus !=='Others') {
            this.showToast('Error', 'Please select Unit!', 'error');
            return;
        }
        
        if (fields[ContactId.fieldApiName] == null && this.customerTypeStatus !=='Visitor' && this.customerTypeStatus !=='Others') {
            this.showToast('Error', 'Please select Contact!', 'error');
            return;
        }
        if(this.CaseCommentsValue == null || this.CaseCommentsValue =='')
            {
                this.showToast('Error', 'Please enter Comment', 'error');
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
        if ((this.CustomerTypeValue == 'Tenant' && (fields[SuppliedEmail.fieldApiName] == null || fields[SuppliedEmail.fieldApiName] == '')) ||
            (this.CustomerTypeValue == 'Tenant' && (fields[SuppliedName.fieldApiName] == null  || fields[SuppliedName.fieldApiName] == ''))) {
            this.showToast('Error', 'Please Enter Tenant Name/Email/Phone. ', 'error');
            return;
        }

        if ((this.CustomerTypeValue == 'Visitor' && (fields[SuppliedEmail.fieldApiName] == null || fields[SuppliedEmail.fieldApiName] == '')) ||
            (this.CustomerTypeValue == 'Visitor' && (fields[SuppliedName.fieldApiName] == null || fields[SuppliedName.fieldApiName] == '' ))) {
            this.showToast('Error', 'Please Enter Visitor Name/Email/Phone. ', 'error');
            return;
        }      
        

     
       console.log('customerTypeStatus '+ this.customerTypeStatus); 
       console.log('accountId '+ this.AccountValue); 
       
       //console.log('accountId2 '+ this.AccountValueInput); 
        checkDuplicate({
            unitValue: this.UnitValueInput != null ? this.UnitValueInput : this.UnitValue,
            categoryValue: this.CaseCategoryValue,            
            subCategoryValue: this.SubCatValue,
            accountIdVal: this.customerTypeStatus == 'Others' ? this.AccountValue : null
        })       
            .then(isDuplicate => {
                                             
                console.log('In Check Duplicate');          
                if (isDuplicate.length>0 && this.customerTypeStatus !=='Visitor') {
                    this.showToast('Error', 'Duplicate case found with same Unit, Case Category & Case Sub Category ', 'error');
                    this.isLoading = false;
                } else {
                    // Create the case record
                    const caseRecord = { apiName: CASE_OBJECT.objectApiName, fields: fields };
                    console.log('caseRecord :::::::>>>>>>>', JSON.stringify(caseRecord)); 
                    createRecord(caseRecord)
                        .then(result => {
                            console.log('result :::::::>>>>>>>', JSON.stringify(result)); 
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
                                this.closeTab();
                            }
                        })
                        .catch(error => {
                            console.log('ERROR :::::::>>>>>', error); 
                            if(error)
                            {
                               
                            this.isLoading = false;
                          
                            this.handleError(error);
                            }
                        });
                }
            })
            .catch(error => {
                this.isLoading = false;

              
                this.handleError(error);
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
        if (error.body && error.body.output && JSON.stringify(error.body.output.fieldErrors) !=='{}') {
          
            fieldErrors = Object.values(error.body.output.fieldErrors).flat();
            this.errorMessages = fieldErrors.map(err => err.message);
           
        }else if (error.body && error.body.output && JSON.stringify(error.body.output.errors) !=='{}') {
            fieldErrors = Object.values(error.body.output.errors).flat();
            this.errorMessages = fieldErrors.map(err => err.message);
           
        }

        this.showToast('Error', 'Failed to Update Record: ' + JSON.stringify(this.errorMessages), 'error');
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

}