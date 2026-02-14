import { LightningElement, wire, track, api } from "lwc";
import { CurrentPageReference, NavigationMixin  } from 'lightning/navigation';
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import createOpportunityEOI from "@salesforce/apex/OpportunityEOIService.createOpportunityEOI";
import getOpportunityEOIQuery from "@salesforce/apex/OpportunityEOIService.getOpportunityEOIQuery";
import createDocumentRecord from "@salesforce/apex/DocumentService.createDocumentRecord";
import insertDocumentRecords from "@salesforce/apex/DocumentService.insertDocumentRecords";
import checkOpportunityEOI from "@salesforce/apex/OpportunityEOIService.checkOpportunityEOI";
import getEOIRangeQuery from "@salesforce/apex/EOIRangeService.getEOIRangeQuery";
import accountsFieldsValidation from "@salesforce/apex/AccountService.accountsFieldsValidation";
import opportunityFieldsValidation from "@salesforce/apex/OpportunityService.opportunityFieldsValidation";
import getOpportunityQuery from "@salesforce/apex/OpportunityService.getOpportunityQuery";
import paymentMode from "@salesforce/schema/OpportunityEOI__c.PaymentMode__c";
import { getListUi } from "lightning/uiListApi";
export default class CreateOpportunityEOI extends NavigationMixin(LightningElement) {
    opportunityFieldValue;
    projectNamePickListValues = [];
    buildingSectionNamePickListValues;
    unitModelPickListValues;
    unitTypePickListValues;
    unitFeaturesPickListValues;
    paymentModePickListValues;
    doneTypingInterval = 0;
    currentPageReference = null; 
    urlStateParameters = null;
    opportunityData;
    isLoading=false;
    checkOpportunityEOIRelated;
    opportunityEOIId;
    @track projectNameField;
    @track buildingSectionNameField;
    @track unitModelField;
    @track unitTypeField;
    @track unitFeatureslField;
    @track priceRangeToField;
    @track interestFeeField;
    @track disableButton = false;
    @track disableBuildingDropdown = true;
    @track disableUnitModalDropdown = true;
    @track disableUnitTypeDropdown = true;
    @track disableUnitFeaturesDropdown = true;
    @track openModal = false;
    @track openErrorModal = false;
    @track alertLabelValue = '';
    @track accountalertLabelValue = '';
    @track opportunityAlertLabelValue = '';
    @track numberOfUnits;
    @track disablePaymentmode = true;
    @track selectedPaymentMode = '';
    @track disableNumberOfUnits = false;
    interestFeeFieldBackUp;
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
       if (currentPageReference) {
            this.urlStateParameters = currentPageReference.attributes.recordId;
            this.opportunityFieldValue = this.urlStateParameters || null;
       }
    }
    navigateToOpportunityEOIRecord() {
        // console.log('Navigation');
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.opportunityEOIId,
                objectApiName: 'OpportunityEOI__c',
                actionName: 'view'
                
            }
        });
    }
    @wire(getPicklistValues, {
        recordTypeId: "012000000000000AAA",
        fieldApiName: paymentMode
    })
    paymentModePickLists({ error, data }) {
        if (error) {
            // console.error("error", error);
        } else if (data) {
            this.paymentModePickListValues = [
                ...data.values
            ];
        }
    }
    handleChange(event) {
        console.log('handle change');
        this[event.target.name] = event.target.value;
        if(event.target.name == 'numberOfUnits'){
            if(event.target.value != undefined && event.target.value != null && event.target.value != ''){
                this.interestFeeField = this.interestFeeFieldBackUp * event.target.value;
            }
        }
        if(event.target.name == 'paymentModeField'){
            this.selectedPaymentMode = event.target.value;
            this.paymentModeField = this.selectedPaymentMode;
        }
        if(this.interestFeeField != 0){
            this.disablePaymentmode=false;  
        }else if(this.interestFeeField == 0){
          this.disablePaymentmode=true;
          this.selectedPaymentMode = 'NA';
          this.paymentModeField = 'NA';
        }
        this.getPriceRanges();
    }
    handleKeyUp(event) {
        clearTimeout(this.typingTimer);
        let value = event.target.value;
        let name = event.target.name;
        this.typingTimer = setTimeout(() => {
            this[name] = value;
        }, this.doneTypingInterval);
    }
    async getProjectDropDownData(){
        
        let dropdownData = [];
        let projectNameData = [];
        let buildingSectionNameData = [];
        let unitModelData = [];
        let unitFeaturesData = [];
        let unitTypeData = [];
        this.opportunityFieldValue = this.urlStateParameters;
        if (this.projectNameField == '' || this.projectNameField == null || this.projectNameField == undefined ) {
        
            const query = 'SELECT ProjectName__c FROM EOIRange__c Where isActive__c = true LIMIT 200';
            dropdownData = await getEOIRangeQuery({query:query});
            //const opportunityQuery = 'SELECT AccountId,Project__c FROM Opportunity WHERE Id  = \'' + this.opportunityFieldValue +'\'';
            //let opportunityProject = await getOpportunityQuery({query:opportunityQuery});
            for (let i = 0; i < dropdownData.length; i++)
            {
                if (dropdownData[i].ProjectName__c) {
                    projectNameData.push({ label: dropdownData[i].ProjectName__c, value: dropdownData[i].ProjectName__c });
                    /*
                    if (opportunityProject[0].Project__c == dropdownData[i].ProjectName__c) {
                        this.projectNameField = dropdownData[i].ProjectName__c;
                    }
                    */
                }
            }
            let filteredProjectNameData = projectNameData.reduce((acc, current) => {
                const x = acc.find(item => item.label === current.label);
                if (!x) {
                  return acc.concat([current]);
                } else {
                  return acc;
                }
            }, []);
            this.projectNamePickListValues = filteredProjectNameData;   
        }else{
            const query2 = 'SELECT BuildingName__c,UnitType__c,UnitModel__c,UnitFeatures__c FROM EOIRange__c WHERE isActive__c = true and ProjectName__c  = \'' + this.projectNameField +'\'';
            dropdownData = await getEOIRangeQuery({query:query2});
            for (let i = 0; i < dropdownData.length; i++)
            {
                if (dropdownData[i].BuildingName__c) {
                    buildingSectionNameData.push({ label: dropdownData[i].BuildingName__c, value: dropdownData[i].BuildingName__c });
                }
                if (dropdownData[i].UnitType__c) {
                    unitTypeData.push({ label: dropdownData[i].UnitType__c, value: dropdownData[i].UnitType__c });
                }
                if (dropdownData[i].UnitModel__c) {
                    unitModelData.push({ label: dropdownData[i].UnitModel__c, value: dropdownData[i].UnitModel__c });
                }
                if (dropdownData[i].UnitFeatures__c) {
                    unitFeaturesData.push({ label: dropdownData[i].UnitFeatures__c, value: dropdownData[i].UnitFeatures__c });
                }
            }
            const filteredBuildingSectionNameData = buildingSectionNameData.reduce((acc, current) => {
                const x = acc.find(item => item.label === current.label);
                if (!x) {
                  return acc.concat([current]);
                } else {
                  return acc;
                }
            }, []);
            const filteredUnitTypeData = unitTypeData.reduce((acc, current) => {
                const x = acc.find(item => item.label === current.label);
                if (!x) {
                  return acc.concat([current]);
                } else {
                  return acc;
                }
            }, []);
            const filteredUnitModelData = unitModelData.reduce((acc, current) => {
                const x = acc.find(item => item.label === current.label);
                if (!x) {
                  return acc.concat([current]);
                } else {
                  return acc;
                }
            }, []);
            const filteredUnitFeaturesData = unitFeaturesData.reduce((acc, current) => {
                const x = acc.find(item => item.label === current.label);
                if (!x) {
                  return acc.concat([current]);
                } else {
                  return acc;
                }
            }, []);
            
            this.buildingSectionNamePickListValues = filteredBuildingSectionNameData;
            this.unitTypePickListValues = filteredUnitTypeData;
            this.unitModelPickListValues = filteredUnitModelData;
            this.unitFeaturesPickListValues = filteredUnitFeaturesData;
            this.numberofUnits = 0;
        }
    }
    async getUnitTypeDropDownData(){
        
        let dropdownData = [];
        let unitFeaturesData = [];
        this.opportunityFieldValue = this.urlStateParameters;
        const query2 = 'SELECT UnitFeatures__c FROM EOIRange__c WHERE isActive__c = true and BuildingName__c  = \'' + this.buildingSectionNameField +'\' and UnitType__c  = \'' + this.unitTypeField +'\' and UnitModel__c = \'' + this.unitModelField +'\'';
        dropdownData = await getEOIRangeQuery({query:query2});
        for (let i = 0; i < dropdownData.length; i++)
        {
            if (dropdownData[i].UnitFeatures__c) {
                unitFeaturesData.push({ label: dropdownData[i].UnitFeatures__c, value: dropdownData[i].UnitFeatures__c });
            }
        }
        const filteredUnitFeaturesData = unitFeaturesData.reduce((acc, current) => {
            const x = acc.find(item => item.label === current.label);
            if (!x) {
              return acc.concat([current]);
            } else {
              return acc;
            }
        }, []);
            
        this.unitFeaturesPickListValues = filteredUnitFeaturesData;
    }
    async getUnitModalDropDownData(){
        
        let dropdownData = [];
        let unitFeaturesData = [];
        let unitTypeData = [];

        this.opportunityFieldValue = this.urlStateParameters;
        const query2 = 'SELECT UnitType__c,UnitFeatures__c,BuildingSectionEOIFee__c FROM EOIRange__c WHERE isActive__c = true and BuildingName__c  = \'' + this.buildingSectionNameField +'\' and UnitModel__c = \'' + this.unitModelField +'\'';
        dropdownData = await getEOIRangeQuery({query:query2});
        for (let i = 0; i < dropdownData.length; i++)
        {
            if (dropdownData[i].UnitType__c) {
               unitTypeData.push({ label: dropdownData[i].UnitType__c, value: dropdownData[i].UnitType__c });
            }
            if (dropdownData[i].UnitFeatures__c) {
                unitFeaturesData.push({ label: dropdownData[i].UnitFeatures__c, value: dropdownData[i].UnitFeatures__c });
            }
        }
        const filteredUnitTypeData = unitTypeData.reduce((acc, current) => {
            const x = acc.find(item => item.label === current.label);
            if (!x) {
              return acc.concat([current]);
            } else {
              return acc;
            }
        }, []);
        const filteredUnitFeaturesData = unitFeaturesData.reduce((acc, current) => {
            const x = acc.find(item => item.label === current.label);
            if (!x) {
              return acc.concat([current]);
            } else {
              return acc;
            }
        }, []);
            
        this.unitTypePickListValues = filteredUnitTypeData;
        this.unitFeaturesPickListValues = filteredUnitFeaturesData;
        this.interestFeeField = dropdownData[0].BuildingSectionEOIFee__c;
        this.interestFeeFieldBackUp = dropdownData[0].BuildingSectionEOIFee__c;
    }
    async getBuildingDropDownData(){
        
        let dropdownData = [];
        let unitModelData = [];
        let unitFeaturesData = [];
        let unitTypeData = [];
        this.opportunityFieldValue = this.urlStateParameters;
        const query2 = 'SELECT UnitType__c,UnitModel__c,UnitFeatures__c,BuildingSectionEOIFee__c FROM EOIRange__c WHERE isActive__c = true and BuildingName__c  = \'' + this.buildingSectionNameField +'\'';
        dropdownData = await getEOIRangeQuery({query:query2});
        for (let i = 0; i < dropdownData.length; i++)
        {
            if (dropdownData[i].UnitType__c) {
               unitTypeData.push({ label: dropdownData[i].UnitType__c, value: dropdownData[i].UnitType__c });
            }
            if (dropdownData[i].UnitModel__c) {
                unitModelData.push({ label: dropdownData[i].UnitModel__c, value: dropdownData[i].UnitModel__c });
            }
            if (dropdownData[i].UnitFeatures__c) {
                unitFeaturesData.push({ label: dropdownData[i].UnitFeatures__c, value: dropdownData[i].UnitFeatures__c });
            }
        }
        const filteredUnitTypeData = unitTypeData.reduce((acc, current) => {
            const x = acc.find(item => item.label === current.label);
            if (!x) {
              return acc.concat([current]);
            } else {
              return acc;
            }
        }, []);
        const filteredUnitModelData = unitModelData.reduce((acc, current) => {
            const x = acc.find(item => item.label === current.label);
            if (!x) {
              return acc.concat([current]);
            } else {
              return acc;
            }
        }, []);
        const filteredUnitFeaturesData = unitFeaturesData.reduce((acc, current) => {
            const x = acc.find(item => item.label === current.label);
            if (!x) {
              return acc.concat([current]);
            } else {
              return acc;
            }
        }, []);
            
        this.unitTypePickListValues = filteredUnitTypeData;
        this.unitModelPickListValues = filteredUnitModelData;
        this.unitFeaturesPickListValues = filteredUnitFeaturesData;
        this.interestFeeField = dropdownData[0].BuildingSectionEOIFee__c;
        this.interestFeeFieldBackUp = dropdownData[0].BuildingSectionEOIFee__c;
        
    }
    async getPriceRanges(){
        if (this.unitModelField == '' || this.unitModelField == null || this.unitModelField == undefined ||
        this.unitTypeField == '' || this.unitTypeField == null || this.unitTypeField == undefined ||
        this.unitFeatureslField == '' || this.unitFeatureslField == null || this.unitFeatureslField == undefined) {
        } else{                                                      
            const query2 = 'SELECT MaxPriceRange__c  ,MinPriceRange__c FROM EOIRange__c WHERE isActive__c = true and ProjectName__c  = \'' + this.projectNameField +'\' AND BuildingName__c  = \'' + this.buildingSectionNameField +'\' AND UnitFeatures__c  = \'' + this.unitFeatureslField +'\' AND UnitModel__c  = \'' + this.unitModelField +'\' AND UnitType__c  = \'' + this.unitTypeField +'\'';
            // console.log(query2);
            let dropdownData = await getEOIRangeQuery({query:query2});
            this.priceRangeFromField = dropdownData[0].MinPriceRange__c;
            this.priceRangeToField = dropdownData[0].MaxPriceRange__c;
        }
    }
    async handleProjectChange(event) {
        this.disableNumberOfUnits = false;
        this[event.target.name] = event.target.value;
        this.getProjectDropDownData();
        this.disableBuildingDropdown = false;
        this.disableUnitModalDropdown = true; 
        this.disableUnitTypeDropdown = true;
        this.disableUnitFeaturesDropdown = true;
        this.buildingSectionNameField= '';
        this.unitModelField= '';
        this.unitTypeField= '';
        this.unitFeatureslField= '';
        this.priceRangeFromField = '';
        this.priceRangeToField = '';
        this.interestFeeField = '';
        this.numberofUnits = '';
        if(this.projectNameField == 'Nobu Residences Abu Dhabi'){
            this.disableNumberOfUnits = true;
        }
    }
    async handleBuildingChange(event) {
        this[event.target.name] = event.target.value;
        this.getBuildingDropDownData();
        this.disableUnitModalDropdown = false;
        this.disableUnitTypeDropdown = true;
        this.disableUnitFeaturesDropdown = true;
        this.priceRangeFromField = '';
        this.priceRangeToField = '';
        this.unitModelField= '';
        this.unitTypeField= '';
        this.unitFeatureslField= '';
    }
    async handleUnitModalChange(event) {
        this[event.target.name] = event.target.value;
        this.numberofUnits = '';
        this.getUnitModalDropDownData();
        this.disableUnitTypeDropdown = false;
        this.disableUnitFeaturesDropdown = true;
        this.priceRangeFromField = '';
        this.priceRangeToField = '';
        this.unitTypeField= '';
        this.unitFeatureslField= '';

    }
    async handleUnitTypeChange(event) {
        this[event.target.name] = event.target.value;
        this.disableUnitFeaturesDropdown = false;
        this.getUnitTypeDropDownData();
        this.unitFeatureslField= '';
        this.priceRangeFromField = '';
        this.priceRangeToField = '';
    }
    async createOpportunityEOI(event) {
        try {
        this.isLoading=true;
        this.disableButton = true;
        // console.log(this.opportunityFieldValue);
        // console.log(this.projectNameField);
        // console.log(this.buildingSectionNameField);
        // console.log(this.unitModelField);
        // console.log(this.unitTypeField);
        // console.log(this.unitFeatureslField);
        // console.log(this.paymentModeField);
        // console.log(this.priceRangeFromField);
        // console.log(this.priceRangeToField);
        // console.log(this.interestFeeField);
        // console.log(this.remarksField);
        
        
        //let opportunityFieldValidationAlert = await opportunityFieldsValidation({opportunityId:this.opportunityFieldValue})
        let accountFieldValidationAlert = await accountsFieldsValidation({accountId:this.opportunityData[0].AccountId })
        if (this.opportunityFieldValue == '' || this.opportunityFieldValue == null || this.opportunityFieldValue == undefined || 
        this.projectNameField == '' || this.projectNameField == null || this.projectNameField == undefined  || 
        this.buildingSectionNameField == '' || this.buildingSectionNameField == null || this.buildingSectionNameField == undefined || 
        this.unitModelField == '' || this.unitModelField == null || this.unitModelField == undefined || 
        this.unitTypeField == '' || this.unitTypeField == null || this.unitTypeField == undefined || 
        this.unitFeatureslField == '' || this.unitFeatureslField == null || this.unitFeatureslField == undefined || 
        this.paymentModeField == '' || this.paymentModeField == null || this.paymentModeField == undefined || (this.numberOfUnits == undefined && !this.disableNumberOfUnits )) {
            this.alertLabelValue = 'Please fill missing mandatory fields.';
            this.disableButton = false;
        // } else if (opportunityFieldValidationAlert != null && opportunityFieldValidationAlert != '' && opportunityFieldValidationAlert != undefined) {
        //     this.opportunityAlertLabelValue = 'Please provide Opportunity ' + opportunityFieldValidationAlert;
        //     this.disableButton = false;
        }else if (accountFieldValidationAlert != null && accountFieldValidationAlert != '' && accountFieldValidationAlert != undefined) {
            this.accountalertLabelValue = 'Please provide Account ' + accountFieldValidationAlert;
            this.disableButton = false;
        }else if(!this.disableNumberOfUnits &&  this.numberOfUnits <= 0){
            this.alertLabelValue = 'Number of Units should be >=1.';
            this.disableButton = false;
        }else{
            this.isLoading=true;
            const eOIRangeQuery = 'SELECT Id,BuildingSectionName__c,Project__c FROM EOIRange__c WHERE isActive__c = true and BuildingName__c  = \'' + this.buildingSectionNameField +'\' and UnitFeatures__c  = \'' + this.unitFeatureslField +'\' and UnitModel__c  = \'' + this.unitModelField +'\' and UnitType__c  = \'' + this.unitTypeField +'\'';
            // console.log(eOIRangeQuery);
            let data = await getEOIRangeQuery({query:eOIRangeQuery});
            
            await createOpportunityEOI({ opportunity:this.opportunityFieldValue, account: this.opportunityData[0].AccountId, projectName:data[0].Project__c, buildingSectionName:data[0].BuildingSectionName__c, 
            unitModel:this.unitModelField, unitType:this.unitTypeField, unitFeatures:this.unitFeatureslField, paymentMode:this.paymentModeField, remarks: this.remarksField, customerPreference: this.customerPreferenceField,
            priceRangeFrom:this.priceRangeFromField, priceRangeTo:this.priceRangeToField, interestFee:this.interestFeeField, numberOfUnits:this.numberOfUnits, eOIRange:data[0].Id});
            
            const opportunityEOIQuery = 'select Id from OpportunityEOI__c where Opportunity__c = \'' + this.opportunityFieldValue + '\' order by createdDate desc limit 1';
            // console.log(opportunityEOIQuery);
            let opportunityEOIData = await getOpportunityEOIQuery({query:opportunityEOIQuery});
            this.opportunityEOIId = opportunityEOIData[0].Id;
            // var documentArray = [];
            // documentArray.push(await createDocumentRecord({ opportunity:this.opportunityFieldValue, expressionofInterest:this.opportunityEOIId , unit:'', documentType: 'EOI Agreement', opportunityUnit:'', account:''}));
            // await insertDocumentRecords({documentList: documentArray})
            this.closeModal();
            this.resetAll();
            this.navigateToOpportunityEOIRecord();
            this.isLoading=false;
        }
        this.isLoading=false;
        } catch (error) {
            this.alertLabelValue = 'An error has occured. Please contact your system administrator.';
            this.isLoading=false;
            return;
        }
        
    }
    async resetAll() {
        // console.log('resetall');
        this.buildingSectionNameField= '';
        this.projectNameField = '';
        this.unitModelField= '';
        this.unitTypeField= '';
        this.unitFeatureslField= '';
        this.priceRangeFromField= '';
        this.priceRangeToField= '';
        this.interestFeeField= '';
        this.paymentModeField = '';
        this.customerPreferenceField = '';
        this.remarksField = '';
        this.disableButton = false;
        this.disableBuildingDropdown = true;
        this.disableUnitModalDropdown = true;
        this.alertLabelValue = '';
        this.accountalertLabelValue = '';
        this.opportunityAlertLabelValue = '';
        this.numberofUnits = '';
        const lwcComboboxFields = this.template.querySelectorAll(
            'lightning-combobox'
        );
        if (lwcComboboxFields) {
            lwcComboboxFields.forEach(field => {
                field.value = '';
            });
        }
        const lwcInputFields = this.template.querySelectorAll(
            'lightning-input'
        );
        if (lwcInputFields) {
            lwcInputFields.forEach(field => {
                field.value = '';
            });
        }
        const opportunityQuery = 'SELECT AccountId,Project__c FROM Opportunity WHERE Id  = \'' + this.opportunityFieldValue +'\'';
        this.opportunityData = await getOpportunityQuery({query:opportunityQuery});
        let accountFieldValidationAlert = await accountsFieldsValidation({accountId:this.opportunityData[0].AccountId });
        this.getProjectDropDownData();
        //let opportunityFieldValidationAlert = await opportunityFieldsValidation({opportunityId:this.opportunityFieldValue});
        
        // if (opportunityFieldValidationAlert != null && opportunityFieldValidationAlert != '' && opportunityFieldValidationAlert != undefined) {
        //   this.opportunityAlertLabelValue = 'Please provide Opportunity ' + opportunityFieldValidationAlert;
        // }
        if (accountFieldValidationAlert != null && accountFieldValidationAlert != '' && accountFieldValidationAlert != undefined) {
           this.accountalertLabelValue = 'Please provide Account ' + accountFieldValidationAlert;
        }
    }
    OpenModal(){
        if(this.checkOpportunityEOIRelated){
            this.openModal = false;
            this.openErrorModal = true;
        }else{
            this.openErrorModal = false;
            this.openModal = true;
        }
    }
    @api invoke() {
        this.OpenModal();
    }
    closeModal() {
        this.openModal = false;
        this.openErrorModal = false;
        this.alertLabelValue = '';
        this.accountalertLabelValue = '';
        this.opportunityAlertLabelValue = '';
        this.resetAll();
    }
    async connectedCallback() {
        this.checkOpportunityEOIRelated = await checkOpportunityEOI({opportunityId:this.opportunityFieldValue});
        this.resetAll();
    }
}