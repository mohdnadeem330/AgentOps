import { LightningElement,wire,track, api } from 'lwc';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import getDependentMap from "@salesforce/apex/InterDepartmentalReferralController.getDependentMap";
import checkCurrentUsersTeam from "@salesforce/apex/InterDepartmentalReferralController.checkCurrentUsersTeam";
import getCurrentRecord from "@salesforce/apex/InterDepartmentalReferralController.getCurrentRecord";
import LEAD_OBJECT from '@salesforce/schema/Lead';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import referLead from "@salesforce/apex/InterDepartmentalReferralController.referLead";
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import teamValues from '@salesforce/label/c.InterDeptTeams';
import ReferredLeadError from '@salesforce/label/c.ReferredLeadError';
import Lead48HrsToRefer from '@salesforce/label/c.Lead48HrsToRefer';
import LeadReferOwnTeamError from '@salesforce/label/c.LeadReferOwnTeamError';
import LeadReferTeamError from '@salesforce/label/c.LeadReferTeamError';
import LeadReferSuccessMessage from '@salesforce/label/c.LeadReferSuccessMessage';


export default class InterDepartmentleadReferral extends NavigationMixin(LightningElement) {

    controllingPicklist=[];
    dependentPicklist;
    projectList;
    projectVal;
    @track finalDependentVal=[];
    @track finalprojectList=[];
    @track selectedControlling="--None--";
    @track team="--None--";
    @track propertyUsageValue;
    showpicklist = false;
    dependentDisabled=true;
    salesTypeDisabled=true;
    showdependent = false;
    @api recordId;;
    @track isSpinner = false;
    showpropertyUsage = false;
    showproject = false;
    controllingFieldAPI = 'SalesType__c';
    dependingFieldAPI = 'PropertyUsage__c';
    subDependingFieldAPI = 'Project__c';
    depnedentFieldMap = [];
    subDepnedentFieldMap = [];
    disableshowReferButton = true;
    currentUsersTeam = '';
    isAvailableforReferring = false;
    Message='';
    teamLabelValues = {teamValues};
    ReferredLeadError = ReferredLeadError;
    Lead48HrsToRefer = Lead48HrsToRefer;
    LeadReferOwnTeamError = LeadReferOwnTeamError;
    LeadReferTeamError = LeadReferTeamError;
    LeadReferSuccessMessage = LeadReferSuccessMessage;
    
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            this.getLeadRecord();
        }
    }
    connectedCallback(){
     //this.getLeadRecord();
     this.getpicklistValues();
     console.log('this.depnedentFieldMap:::'+JSON.stringify(this.depnedentFieldMap));
     this.getCurrentUsersTeamToRefer();
    }

    getLeadRecord(){
    this.isSpinner = true;
    getCurrentRecord({recordId:this.recordId})
    .then(result => {
        console.log('result in getLead'+ JSON.stringify(result));
      // if(result.LeadAge__c > 0){
        if(((result.ReferredTo__c != null && result.ReferredBy__c != null) || (result.Leads1__r != undefined && result.Leads1__r.length > 0)) ){
          this.isAvailableforReferring = false;
          this.Message=this.ReferredLeadError;
        }else{
          this.isAvailableforReferring = true;
        }
      /* }else {
         this.isAvailableforReferring = false;
         this.Message=this.Lead48HrsToRefer;
       } */
       this.isSpinner = false;
    })
    .catch(error => {
       console.log(error);
       this.isSpinner = false;
    });
   }
    getCurrentUsersTeamToRefer(){
        this.isSpinner = true;
        checkCurrentUsersTeam()
        .then(result => {
            this.currentUsersTeam = result;
            this.isSpinner = false;
        })
        .catch(error => {
           console.log(error);
           this.isSpinner = false;
        });
    }
    getpicklistValues(){
        this.isSpinner = true;
        console.log('this.depnedentFieldMap:::'+JSON.stringify(this.depnedentFieldMap));
        getDependentMap({contrfieldApiName:this.controllingFieldAPI,depfieldApiName:this.dependingFieldAPI})
        .then(result => {
            this.depnedentFieldMap = result;
            this.error = undefined;
           //this.showpicklist = true;
            this.isSpinner = false;
        })
        .catch(error => {
            this.error = error;
            this.depnedentFieldMap = undefined;
            this.isSpinner = false;
        });
    }
    get teamoptions() {
        const teamLabelValues = Object.values(this.teamLabelValues)[0];
        return teamLabelValues.split(',').map(team => ({ label: team, value: team }));
        // return [
        //     { label: 'AUH/DXB', value: 'AUH/DXB' },
        //     { label: 'LAND', value: 'LAND' },
        //    // { label: 'CASA', value: 'CASA' },
        //     { label: 'ReSales', value: 'ReSales' }
        // ];
    }

    onChangeTeam(event){
        this.team = event.target.value;
        this.controllingPicklist = [];
        this.finalDependentVal= [];
        this.projectList = [];
        this.showpropertyUsage = false;
        this.showproject = false;
        this.disableshowReferButton =true;
        if(this.team != null && this.team != undefined && this.team != 'ReSales'){
            this.salesTypeDisabled = false;
            this.disableshowReferButton = true;
            this.showpicklist = true;
        }else if(this.team == 'ReSales'){
            this.disableshowReferButton = false;
            this.salesTypeDisabled = true;
            this.showpicklist = false;
        }
        this.controllingPicklist = [];
        this.dependentPicklist = [];

        
        console.log('this.depnedentFieldMap'+this.depnedentFieldMap);
        if(this.depnedentFieldMap != null){
        for(let key in this.depnedentFieldMap){
        if(this.team == 'LAND' && key=='Commercial Land'){
          this.controllingPicklist.push({"label":key,"value": key})
        }else if(this.team == 'AUH/DXB' && (key=='Institutional' || key=='Residential Sale' || key=='Asset Management')){
            this.controllingPicklist.push({"label":key,"value": key})
        }
    for(let i=0; i<this.depnedentFieldMap[key].length; i++){
            this.dependentPicklist.push({"label":this.depnedentFieldMap[key][i],"value": this.depnedentFieldMap[key][i]});
        }
       }
      }
    }

    fetchDependentValue(event){
        this.isSpinner = true;
        console.log('this.controllingPicklist::'+this.controllingPicklist);
      
        this.finalDependentVal = [];
        const selectedValue = event.target.value;
        this.selectedControlling = selectedValue;
        
        for(let i=0; i<this.depnedentFieldMap[selectedValue].length; i++){
            this.finalDependentVal.push({"label":this.depnedentFieldMap[selectedValue][i],"value": this.depnedentFieldMap[selectedValue][i]});
        }
        this.showpropertyUsage = true;
        getDependentMap({contrfieldApiName:this.dependingFieldAPI,depfieldApiName:this.subDependingFieldAPI})
        .then(result => {
            this.subDepnedentFieldMap = result;
            this.error = undefined;
            this.showpicklist = true;
            this.isSpinner = false;
        })
        .catch(error => {
            this.error = error;
            this.subDepnedentFieldMap = undefined;
            this.isSpinner = false;
        }); 

    }
    onChangeOfPropertyUsage(event){
     this.propertyUsageValue = event.target.value;
     this.projectList = [];
      console.log('this.subDepnedentFieldMap::'+this.subDepnedentFieldMap);
       for(let i=0; i<this.subDepnedentFieldMap[this.propertyUsageValue].length; i++){
        this.projectList.push({"label":this.subDepnedentFieldMap[this.propertyUsageValue][i],"value": this.subDepnedentFieldMap[this.propertyUsageValue][i]});
      }   
      this.showproject = true;
    }

    onChangeOfProject(event){
        this.projectVal = event.target.value; 
        if(this.projectVal != null && this.projectVal != '' && this.projectVal != undefined){
           this.disableshowReferButton = false;
        }
    }
    handleCancel(event){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSubmit(event){
        let errorMsg = '';
        if (this.currentUsersTeam === this.team) {
            errorMsg = this.LeadReferOwnTeamError;
        } else if ((['AUH', 'DXB'].includes(this.currentUsersTeam)) && this.team === 'AUH/DXB') {
            errorMsg = this.LeadReferTeamError;
        }
        if (errorMsg) {
            this.showToast('Error', errorMsg, 'error');
        }else{
            this.isSpinner = true;
            referLead({
                recordId: this.recordId,
                Team: this.team,
                SalesType: this.selectedControlling,
                PropertyUsage: this.propertyUsageValue,
                Project: this.projectVal
            }).then(result => {
                const variant = result.includes('Success') ? 'success' : 'error';
                const message = result.includes('Success') ? this.LeadReferSuccessMessage : 'Error';

                this.showToast(result.includes('Success') ? 'Success' : 'Error', message, variant);
                if (result.includes('Success')) {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: this.recordId,
                            actionName: 'view'
                        }
                    });
                }
            })
            .catch(error => this.showToast('Error', error.message || 'An error occurred', 'error'))
            .finally(() => this.isSpinner = false);
        }
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}