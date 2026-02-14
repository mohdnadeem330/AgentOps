import { LightningElement, api, wire, track } from 'lwc';
    import { createRecord, getRecord, updateRecord } from 'lightning/uiRecordApi';
    import { getObjectInfo, getPicklistValuesByRecordType, getPicklistValues } from 'lightning/uiObjectInfoApi';
    import { getListUi } from 'lightning/uiListApi';
    import { ShowToastEvent } from 'lightning/platformShowToastEvent';
    //import scriptresource from "@salesforce/resourceUrl/casefile";
    import { NavigationMixin,CurrentPageReference } from 'lightning/navigation';
    import { CloseActionScreenEvent } from 'lightning/actions';
    import CASE_OBJECT from '@salesforce/schema/Case';
    import ACCOUNT_OBJECT from '@salesforce/schema/Account';
    import ParentId from '@salesforce/schema/Case.ParentId';
    import ID_FIELD from '@salesforce/schema/Case.Id';
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
    import RecordTypeId from '@salesforce/schema/Case.RecordTypeId';
    import RecordTypeName from '@salesforce/schema/Case.Recordtype_Name__c';
    import CaseOrigin from '@salesforce/schema/Case.Origin';
    import isFCR from '@salesforce/schema/Case.FCR__c';
    import getAccountid from '@salesforce/apex/ManageCasesController.getAccountid';
    import LightningConfirm from 'lightning/confirm';
    import checkDuplicate from '@salesforce/apex/CaseService.checkDuplicate';
    import CheckUserEditPermission from '@salesforce/apex/CaseService.checkUpdatePermission';
    import accountNameLabel from '@salesforce/label/c.Visitor_Account';
    import hasSalesOrdersForCaseAccount from '@salesforce/apex/ManageCasesController.hasSalesOrdersForCaseAccount';
    import Location from '@salesforce/schema/Case.Location__c';

    export default class UpdateCloneCase extends NavigationMixin(LightningElement)  {
        isVisitorCase = false;
        previousCatValue
        previousSubCatValue
        previousUnitValue
        CustomerTypeValue
        CustomerTypeDisabled =false;
        SubVerticleValue
        CaseCategoryValue
        SubStatusValue
        SubjectValue
        CaseOriginValue
        CaseCommentsValue
        isFcrDisabled
        @track UnitValue
        selectedOption
        @track AccountValue
        AccountValueInput
        UnitValueInput
        ContactValue
        disabledCategory =false;
        accountRelatedFielsDisabled =false;
        SubCatValue
        pickSubCatValue
        pickContactValues
        isFCR = false
        pickCustomerType;
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
        selectedvalue='';
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
        preOriginValue ;
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
        isLoading = false;
        readonlycustomerType = false
        readonlyTenant = false
        readonlyVisitor = false
        Disabledfields = false
        caseOriginDisabled=false;
        TenantReadOnly = false;
        VisitorReadOnly = false;
        VisitorReadOnlyMobile = false;
        showError = false;
        @track hasSalesOrders = false;
        ShowLocation = false;
        picklocationValue
        LocationValue

        connectedCallback() {
            this.Disabledfields =true;
            this.CustomerTypeDisabled =true;
            this.accountRelatedFielsDisabled =true;
            this.caseOriginDisabled =true;
        }

        get options() {
            return [
                { label: 'Queries', value: 'Queries' },
                { label: 'Request', value: 'Requests' },
                { label: 'Complaint', value: 'Complaints' },
            ];
        }

        CloseUpdateScreen() {
            this.dispatchEvent(new CloseActionScreenEvent());
          }

        @wire(getRecord, { recordId: '$recordId',
            fields: [Customer_TYPE, CASE_CATEGORY,CASE_SUB_CATEGORY, UNIT,ACCOUNT_ID,SuppliedPhone, SuppliedName,SuppliedEmail,ContactId,Subject,Description,CaseOrigin, isFCR, RecordTypeId,RecordTypeName,status,Substatus]})
            caseDetail({data, error})
            {
                if(data){
                    this.caseDetails = data;
                    this.selectedOption = data.fields.Recordtype_Name__c.value;
                    this.recordTypeId = data.fields.RecordTypeId.value;
                    this.objectrecordtypeid = data.fields.RecordTypeId.value;
                    //this.loaddata(data);

                }
            }

        loaddata(datavalue)
        {
            
            this.isFCR = datavalue.fields.FCR__c.value;
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
       
            this.SubjectValue = datavalue.fields.Subject.value !=null ? datavalue.fields.Subject.value :null;
            this.CaseCommentsValue = datavalue.fields.CaseComments__c.value !=null ? datavalue.fields.CaseComments__c.value :null;
            this.accountRelatedFielsDisabled =true;
            this.preOriginValue = datavalue.fields.Origin.value;
            this.CaseOriginValue = datavalue.fields.Origin.value;
            this.CustomerTypeValue = datavalue.fields.CustomerType__c.value !=null ? datavalue.fields.CustomerType__c.value :null;
            if(!datavalue.fields.CustomerType__c.value)
            {
                this.CustomerTypeDisabled =false;
            }
            
           
            if(datavalue.fields.Status.value =='New' || datavalue.fields.Status.value =='Work In Progress' || datavalue.fields.Status.value =='Re Opened')
                {
                   
                    this.ispicklistdisabled =false;
                    this.disabledCategory = false;
                    this.isFcrDisabled =false;
                    if(this.CaseOriginValue == 'Email' || this.CaseOriginValue == 'Customer Portal')
                        {
                            this.CustomerTypeDisabled =false;
                        }
                    
                }
                else
                {
                    this.CustomerTypeDisabled =true;
                    this.ispicklistdisabled =true;
                    this.disabledCategory = true;
                    this.isFcrDisabled =true;
                }
                if(this.CaseOriginValue == 'Customer Portal')
                {
                    this.Disabledfields =true;
                 
                    this.caseOriginDisabled =true;
                    this.pickCustomerType = this.pickCustomerType.filter(val => ['Owner', 'Tenant'].includes(val.value));
                }
            if(this.CaseOriginValue == 'Email')
            {
                
                this.Disabledfields =false;
                this.caseOriginDisabled =true;
            }
            if(this.CustomerTypeValue == 'Owner')
            {
               
            }

            if(this.CustomerTypeValue == 'Tenant')
            {
                this.tenantfields = true;
                this.TenantEmailVal = datavalue.fields.SuppliedEmail.value;
                this.TenantNameVal =  datavalue.fields.SuppliedName.value;
                this.TenantPhoneVal = datavalue.fields.SuppliedPhone.value;
              

            }
            if(this.CustomerTypeValue == 'Visitor')
                {
                    this.VisitorEmailVal = datavalue.fields.SuppliedEmail.value;
                    this.VisitorNameVal = datavalue.fields.SuppliedName.value;
                    this.VisitorPhoneVal = datavalue.fields.SuppliedPhone.value;
                    this.showvisitorfield = true;
                    this.isVisitorCase =true;
                  

                }

            this.CaseCommentsValue = datavalue.fields.CaseComments__c.value !=null ? datavalue.fields.CaseComments__c.value :null;
            this.CaseCategoryValue = datavalue.fields.CaseCategory__c.value !=null ? datavalue.fields.CaseCategory__c.value :null;
            this.previousCatValue = datavalue.fields.CaseCategory__c.value !=null ? datavalue.fields.CaseCategory__c.value :null;
            this.SubStatusValue = datavalue.fields.Sub_Status__c.value !=null ? datavalue.fields.Sub_Status__c.value :null;


            
            let key = this.pickSubController.controllerValues[this.CaseCategoryValue];
            this.pickSubCatValue = this.pickSubController.values.filter(opt => opt.validFor.includes(key));
            this.SubCatValue = datavalue.fields.SubCategory__c.value;
            this.previousSubCatValue = datavalue.fields.SubCategory__c.value;
            
           
            if(datavalue.fields.AccountId.value)
                {   //To make unit selection enable if origin is customer portal or customer app
                    if(this.CaseOriginValue == 'Customer Portal' || this.CaseOriginValue == 'Customer App'){
                        this.accountRelatedFielsDisabled =false;
                    } 
                    this.AccountValue = datavalue.fields.AccountId.value;
                        getAccountid({UnitId: null, AccountId:this.AccountValue })
                        .then(data => {
                        if(data.Contactlist != null)
                        {
                        this.pickContactValues = data.Contactlist.map(con => {
                        return {
                            label: con.Name,
                            value: con.Id
                        };
                        });
                        if(data.AccounType == 'Person')
                        {
                            this.ContactValue = data.Contactlist[0].Id;
                        }
                        else
                        {
                            this.ContactValue = datavalue.fields.ContactId.value
                        }
                        }

                        })
                        .catch(error =>{})
                }
                else
                {
                    this.accountRelatedFielsDisabled =false;
                }
                if(datavalue.fields.Unit__c.value)
                    {
                        //To make unit selection enable if origin is customer portal or customer app
                        if(this.CaseOriginValue == 'Customer Portal' || this.CaseOriginValue == 'Customer App'){
                            this.accountRelatedFielsDisabled =false;
                        } 
                        this.UnitValue = datavalue.fields.Unit__c.value;
                        this.previousUnitValue = datavalue.fields.Unit__c.value;
                    }
                    else
                    {
                        this.accountRelatedFielsDisabled =false;
                    }

                   

        }

        @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
            accountMetadata({ data, error }) {
                if (data) {
                    this.recordTypeIds = data.recordTypeInfos;
                //  this.pickValUnit = data.Unit__c;
                } else if (error) {
                    this.showToast('Error', 'Error fetching record type information: ' + error.body.message, 'error');
                }
            }

        @wire(getPicklistValuesByRecordType, {
                recordTypeId : '$recordTypeId',
                objectApiName : CASE_OBJECT
            })
            wiredRecordTypeInfo({data, error}) {
                if(data) {
                    console.log('data.picklistFieldValues--> ', JSON.stringify(data.picklistFieldValues));
                    this.pickCustomerType = data.picklistFieldValues.CustomerType__c.values;
                    this.pickCustomerType = this.pickCustomerType.filter(val => ['Owner', 'Tenant', 'Visitor'].includes(val.value)
                    )
                    this.picklocationValue = data.picklistFieldValues.Location__c.values;
                    console.log('this.picklocationValue--> ', JSON.stringify(this.picklocationValue));
                    this.pickCaseCategory = data.picklistFieldValues.CaseCategory__c.values;
                    this.caseDetails.fields.Status.value;
                    if(this.caseDetails.fields.Status.value == 'Resolved')
                    {
                        this.pickSubStatus = data.picklistFieldValues.Sub_Status__c.values.filter(opt => opt.validFor.includes(4));
                    }
                    else{
                        this.pickSubStatus = data.picklistFieldValues.Sub_Status__c.values.filter(opt => opt.validFor.includes(1));
                    }

                    this.pickCaseOrigin = data.picklistFieldValues.Origin.values;
                    this.pickCaseOrigin = data.picklistFieldValues.Origin.values.filter(item => {
                        return ['Phone', 'Whatsapp', 'Walk-In','Email','Social','Chat','Portal','Survey','Online','Broker Portal','Customer Portal'].includes(item.value);
                    });
                    this.pickSubController = data.picklistFieldValues.SubCategory__c;
                    if(this.caseDetails){
                        this.loaddata(this.caseDetails)

                    }

                }
                if(error) {

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


            }
        }


 

        handleUpdateClick(){
            this.checkSalesOrders();
            CheckUserEditPermission({caseId : this.recordId}).then(userPermission=>{

    if(userPermission.length > 0){
        console.log('userPermission.length -->', userPermission.length);
        checkDuplicate({
            unitValue: this.UnitValueInput != null ? this.UnitValueInput : this.UnitValue,
            categoryValue: this.CaseCategoryValue,
            subCategoryValue: this.SubCatValue
        })
            .then(async isDuplicate => {
                if(isDuplicate.length >0)
                {
                if(this.CustomerTypeValue === 'Visitor')
                {
                    if(this.CaseOriginValue === 'Email')
                        {
                           
                            if (this.AccountValue == accountNameLabel) {

                                this.ContactValue = null;
                                this.UnitValue = null;
                                this.isVisitorCase =true;

                                this.handleUpdate(null);
                            }
                            else {
                                this.showToast('Error', 'Only the Visitor Account can be selected for cases with Customer Type selected as Visitor.', 'error');
                            }
                        }
                        else
                        {
                            this.handleUpdate(null);
                        }

                    // return;

                }
                else
                {
                    if (this.AccountValue == accountNameLabel)
                    {
                        this.showToast('Error', 'Visitor Account can only be selected for cases with Customer Type selected as Visitor', 'error');
                    }else
                    {
                    if(this.CaseOriginValue === 'Email')
                    {
                        if(this.previousUnitValue == this.UnitValue && this.previousCatValue == this.CaseCategoryValue && this.previousSubCatValue == this.SubCatValue)
                            {

                                this.handleUpdate(null);
                            }
                            else
                            {

                        const result = await LightningConfirm.open({
                            message: 'Duplicate case found with same Unit, Case Category & Case Sub Category.Existing Case Numer -'+JSON.stringify(isDuplicate[0].CaseNumber)+'.Do you still want to create new case?',
                            variant: 'header',
                            label: 'Please Confirm',
                            theme: 'warning',
                        });
                        if(result == true)
                            {

                            this.handleUpdate(isDuplicate[0].Id);
                            }
                        // return;

                    }}
                    else
                    {
                        if(this.previousUnitValue == this.UnitValue && this.previousCatValue == this.CaseCategoryValue && this.previousSubCatValue == this.SubCatValue)
                        {

                            this.handleUpdate(null);
                        }
                        else
                        {

                        this.showToast('Error', 'Duplicate case found with same Unit, Case Category & Case Sub Category', 'error');
                        }
                    //  return;
                    }
                }}
                }
                else
                {
                    console.log('this.CustomerTypeValue >>>>>>>>>>>>>>>>>>>>', this.CustomerTypeValue);
                    if(this.CustomerTypeValue === 'Visitor')
                        {
                           
                            if (this.AccountValue == accountNameLabel) {

                                this.ContactValue = null;
                                this.UnitValue = null;
                                this.isVisitorCase =true;
                                this.handleUpdate(null);
                            }
                            else {
                                this.showToast('Error', 'Only the Visitor Account can be selected for cases with Customer Type selected as Visitor.', 'error');
                            }
                          }
                        //   else if(this.CustomerTypeValue === 'Others'){
                        //     this.handleUpdate(null);
                        //   }
                          else
                          {
                            this.handleUpdate(null);
                          }

                }


            })
            .catch(error => {


            });
    }
    else
    {
        this.showToast('Error', 'You do not have permission to edit this case. Please accept the case first using the "Accept Case" button before making any changes.', 'error');

    }

            }).catch(error =>{ });



        }


        resetproperties(){
           // this.pickSubCatValue =null;
           // this.CaseCategoryValue = null;          
            this.CaseCommentsValue = null;
            this.TenantEmailVal = null;
            this.pickAccountValueInput = null;
            this.pickUnitValueInput = null;
            this.TenantNameVal = null;
            this.TenantPhoneVal = null;
            this.VisitorEmailVal = null;
            this.VisitorNameVal = null;
            this.VisitorPhoneVal = null;
            this.AccountValueInput = null;

        }

        handleChange(event) {
            let name = event.target.name;
            let val = event.target.value;
            if(name === 'CustomerType'){
                this.CustomerTypeValue = val;
                this.Subrequired = true;
                if(val == 'Tenant'){
                    this.tenantfields = true;
                    this.showvisitorfield = false;
                    this.TenantReadOnly = true;
                    this.VisitorReadOnly = false;
                    this.VisitorReadOnlyMobile = false;
                    this.isVisitorCase =false;
                    this.accountRelatedFielsDisabled =false;
                    if(this.CaseOriginValue == 'Customer Portal')
                    {
                        this.accountRelatedFielsDisabled =true;
                    }
                    this.resetproperties();

                }
                if(val == 'Visitor'){
                    this.showvisitorfield = true;
                    this.tenantfields = false;
                    this.VisitorReadOnly = true;
                    this.VisitorReadOnlyMobile = true;
                    this.TenantReadOnly = false;
                    this.AccountValue = accountNameLabel;
                    this.isVisitorCase =true;
                    this.accountRelatedFielsDisabled =true;
                    this.resetproperties();
                    this.VisitorEmailVal = this.caseDetails.fields.SuppliedEmail.value;
                    this.VisitorNameVal = this.caseDetails.fields.SuppliedName.value;
                    this.VisitorPhoneVal = this.caseDetails.fields.SuppliedPhone.value;  
                }
                if(val == 'Owner'){
                    this.showvisitorfield = false;
                    this.tenantfields = false;
                    this.resetproperties();
                    this.TenantReadOnly = false;
                    this.VisitorReadOnly = false;
                    this.VisitorReadOnlyMobile = false;
                    this.accountRelatedFielsDisabled =false;
                    if(this.CaseOriginValue == 'Customer Portal')
                        {
                            this.accountRelatedFielsDisabled =true;
                        }
                    this.isVisitorCase =false;
                }
            } else if (name === 'SubVerticle') {
                this.SubVerticleValue = val;
            }  else if (name === 'CaseCategory') {
                this.CaseCategoryValue = val;

                if(val == 'CMO' || val == 'MEP' ||val == 'Civil' ){
                    this.ShowLocation = true;
                    this.Disabledfields = false;
                }
                else{
                    this.ShowLocation = false;
                } 

                this.selectedvalue = val;
                let key = this.pickSubController.controllerValues[event.target.value];
                this.pickSubCatValue = this.pickSubController.values.filter(opt => opt.validFor.includes(key));
                this.SubCatValue=null;

            }else if(name==='CaseSubStatus')
            {
                this.SubStatusValue =val;
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
            else if (name === 'CaseLocation'){
                this.LocationValue = val;
            }
            if(this.CaseOriginValue == 'Email' && this.CustomerTypeValue =='Visitor')
            {
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

        handleUnitChange(event){

            let val = event.detail.recordId;
            this.UnitValue = this.dlpUnitId!= null ? this.dlpUnitId: val;

            this.UnitValueInput = null;

            if(val!= null)
                {
                    getAccountid({UnitId: val, AccountId: null})
                    .then(data => {
                        if(data.AccountVal != null)
                            {
                        this.pickAccountValueInput = data.AccountList.map(account => {
                            return {
                                label: account.Name,
                                value: account.Id
                            };
                        });
                        this.AccountValueInput = data.AccountVal;
                        this.ShowAccountSearch = false;
                            }
                            if(data.Contactlist != null)
                                {
                            this.pickContactValues = data.Contactlist.map(con => {
                                return {
                                    label: con.Name,
                                    value: con.Id
                                };
                            });


                            if(data.AccounType == "Person")
                                {

                                    this.ContactValue = data.Contactlist[0].Id;

                                }

                            }

                    })
                    .catch(error =>{

                    })
                }
                else{
                    this.ShowAccountSearch = true;
                    this.pickContactValues = null;
                    this.AccountValue = null;
                    this.AccountValueInput = null;
                    this.ContactValue = null;
                }

        }

        handleAccountChange(event){

            let val = event.detail.recordId;
            this.AccountValue = this.dlpAccountId!=null? this.dlpAccountId: val;
            this.UnitValue = null;
            this.UnitValueInput = null;
            this.pickContactValues = null;
            this.AccountValueInput = null;
            this.ShowUnitSearch = true;
            if(val!= null)
                {
                    getAccountid({UnitId: null, AccountId:val })
                    .then(data => {
                        this.ShowUnitSearch = false;
                        if(data.UnitList != null)
                            {
                        this.pickUnitValueInput = data.UnitList.map(unit => {
                            return {
                                label: unit.Name,
                                value: unit.Id
                            };
                        });

                        }
                        if(data.Contactlist != null)
                            {
                        this.pickContactValues = data.Contactlist.map(con => {
                            return {
                                label: con.Name,
                                value: con.Id
                            };
                        });
                        if(data.AccounType == 'Person')
                            {
                                this.ContactValue = data.Contactlist[0].Id;
                            }

                        }

                    })
                    .catch(error =>{

                    })
                }
            }

        handlefields(updateflag,parentCaseId)
            {

                const fields = {};
            if(updateflag == true)
            {
                fields[ID_FIELD.fieldApiName] = this.recordId;
            }

           
            if(this.isVisitorCase == true)
            {
                
                fields[UNIT.fieldApiName] = null;
            }
            else
            {
              

                fields[UNIT.fieldApiName] = this.UnitValueInput != null? this.UnitValueInput : this.UnitValue;
            }
            this.isLoading = true;
            if(parentCaseId !=null)
            {
                fields[ParentId.fieldApiName] = parentCaseId;
            }
            fields[Customer_TYPE.fieldApiName] = this.CustomerTypeValue;
            fields[CASE_CATEGORY.fieldApiName] = this.CaseCategoryValue;
            fields[Substatus.fieldApiName] = this.SubStatusValue;
            fields[Subject.fieldApiName] = this.SubjectValue;
            fields[Description.fieldApiName] = this.CaseCommentsValue;
           // fields[UNIT.fieldApiName] = this.UnitValueInput != null? this.UnitValueInput : this.UnitValue;
            fields[ACCOUNT_ID.fieldApiName] = this.AccountValueInput != null? this.AccountValueInput: this.AccountValue;
           
            fields[ContactId.fieldApiName] = this.ContactValue;

            fields[SuppliedEmail.fieldApiName] = this.TenantEmailVal != null ? this.TenantEmailVal :this.VisitorEmailVal;
            fields[SuppliedName.fieldApiName] = this.TenantNameVal!= null ? this.TenantNameVal :this.VisitorNameVal;
            fields[SuppliedPhone.fieldApiName] = this.TenantPhoneVal!= null ? this.TenantPhoneVal :this.VisitorPhoneVal;
            fields[RecordTypeId.fieldApiName] = this.recordTypeId;
            fields[CaseOrigin.fieldApiName] = this.CaseOriginValue;
            fields[isFCR.fieldApiName] = this.isFCR;

            fields[CASE_SUB_CATEGORY.fieldApiName] = this.SubCatValue;
            fields[Location.fieldApiName] = this.LocationValue;
         
            if(this.CustomerTypeValue == null){
                this.showToast('Error', 'Please select Customer Type!', 'error');
                return;
            }
            if(this.CaseOriginValue == null){
                this.showToast('Error', 'Please select Case Origin!', 'error');
                return;
            }
            if(this.CaseCategoryValue == null){
                this.showToast('Error', 'Please select Case Category!', 'error');
                return;
            }
            if(this.SubCatValue ==null)
            {
                this.showToast('Error', 'Please select Sub Case Category!', 'error');
                return; 
            }
            if(fields[ACCOUNT_ID.fieldApiName] == null){
                this.showToast('Error', 'Please select Account!', 'error');
                return;
            }
            if(fields[UNIT.fieldApiName] == null && this.isVisitorCase == false && this.hasSalesOrders == false){
                this.showToast('Error', 'Please select Unit!', 'error');
                return;
            }

            if(fields[ContactId.fieldApiName] == null  && this.isVisitorCase == false){
                this.showToast('Error', 'Please select Contact!', 'error');
                return;
            }

             if(this.CaseCommentsValue == null || this.CaseCommentsValue.trim() =='')
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

            return fields;

            }



        handleUpdate(parentCaseId) {
            const recordInput = {fields : this.handlefields(true,parentCaseId)}
            updateRecord(recordInput)
                .then(result => {
                   
                    this.isLoading = false;
                    this.showToast('Success', 'Case Updated successfully!', 'success');
                 
                    this.CloseUpdateScreen();
               
                    
                })
                .catch(error => {
                    this.isLoading = false;
                    this.handleError(error);
                })

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
            if (error.body && error.body.output && JSON.stringify(error.body.output.fieldErrors)!=='{}') {
                fieldErrors = Object.values(error.body.output.fieldErrors).flat();
                this.errorMessages = fieldErrors.map(err => err.message);
            }else if (error.body && error.body.output && JSON.stringify(error.body.output.errors!=='{}')) {
                fieldErrors = Object.values(error.body.output.errors).flat();
                this.errorMessages = fieldErrors.map(err => err.message);
            }
            this.ShowMessageValue = this.errorMessages;
            this.showToast('Error', JSON.stringify(this.errorMessages)  , 'error');
        }

        
       checkSalesOrders() {
        hasSalesOrdersForCaseAccount({ caseId: this.recordId })
            .then(result => {
                this.hasSalesOrders = result;
            })
            .catch(error => {
                console.error('Error checking sales orders:', error);
            });
        }

    }