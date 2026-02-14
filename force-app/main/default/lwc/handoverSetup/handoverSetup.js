import { LightningElement, api, wire, track } from 'lwc';
// harsh@aldar added for ReassignKAR
import reAssignKARToServiceRequests  from '@salesforce/apex/HandoverUtility.reAssignKARToServiceRequests'
import getAllProjects from '@salesforce/apex/OpportunityRTOUnitSearchController.getAllProjects';
import getAllBuildings from '@salesforce/apex/OpportunityRTOUnitSearchController.getAllBuildings';
import getUnitDetails from '@salesforce/apex/HandoverUtility.getUnitDetails';
import createHandoverSR from '@salesforce/apex/HandoverUtility.createHandoverSRUpdateSO';
import updateSRDetails from '@salesforce/apex/HandoverUtility.updateSRDetails';
import sendLetter from '@salesforce/apex/HandoverUtility.sendLetter';
import performFinanceVerification from '@salesforce/apex/HandoverUtility.performFinanceVerification';
import getKARList from '@salesforce/apex/HandoverUtility.getKARList';

import HO_HandoverPhasingNotification from '@salesforce/label/c.HO_HandoverPhasingNotification';
import HO_HCLetterNotification from '@salesforce/label/c.HO_HCLetterNotification';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import {getRecord} from 'lightning/uiRecordApi';
import strUserId from '@salesforce/user/Id';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import getSRsrDocID from '@salesforce/apex/HandoverUtility.getSRsrDocID';

//import getProjectToProjectBudget from "@salesforce/apex/OpportunityUnitSearchController.getProjectToProjectBudget";
const actions = [
    { label: 'Show SR details', name: 'sr_details' },
    { label: 'Show SO details', name: 'so_details' },
    { label: 'Show Unit details', name: 'unit_details' },
    { label: 'Handover Details', name: 'ho_details' },
    { label: 'Show SOA', name: 'SOA_details' },
    { label: 'Show ERP SOA', name: 'ERP_SOA_details' }
];

const columns = [
    { label: 'Unit Name', fieldName: 'unitName', initialWidth: 180 ,sortable: true ,hideDefaultActions: true},
    { label: 'RTO', fieldName: 'isRTO', initialWidth: 50 ,sortable: false ,hideDefaultActions: true ,  type: 'boolean'},
    { label: 'Sales Order', fieldName: 'salesOrderName' , initialWidth: 150 ,sortable: true,hideDefaultActions: true },
    //{ label: 'Customer', fieldName: 'customerName' , initialWidth: 200 ,sortable: true,hideDefaultActions: true },
    /*{ label: 'Unit QC Status', fieldName: 'qcStatus', type: 'boolean'},*/
    //{ label: 'ACD Date', fieldName: 'acdDate', type: 'date' , initialWidth: 150 ,sortable: true,hideDefaultActions: true },
    { label: 'Service Request', fieldName: 'srName'  , initialWidth: 150 ,sortable: true,hideDefaultActions: true },
    { label: 'Offered By Projects', fieldName: 'offeredDate', type: 'date' , initialWidth: 150 ,sortable: true, hideDefaultActions: true },
    { label: 'Offered By QA', fieldName: 'qaOfferedDate', type: 'date' , initialWidth: 150,sortable: true,hideDefaultActions: true },
    //{ label: 'CHO Date', fieldName: 'choDate', type: 'date'},
    { label: 'CHO Date', fieldName: 'choDate',  type: 'date', initialWidth: 150,sortable: true ,hideDefaultActions: true},
    //{ label: 'Snagging Appointment', fieldName: 'snagAppointment', initialWidth: 150,sortable: true ,hideDefaultActions: true},
    { label: 'Appointment Booked?', fieldName: 'appointment',type: 'boolean' , initialWidth: 150,sortable: false ,hideDefaultActions: true , cellAttributes: { alignment: 'center' }},
    { label: 'RFO Date', fieldName: 'rfoDate',  type: 'date', initialWidth: 150,sortable: true ,hideDefaultActions: true},
    //{ label: 'Title Deed', fieldName: 'titleDeed', initialWidth: 150,sortable: true ,hideDefaultActions: true},
    //{ label: 'Utility Trnasfer', fieldName: 'utilTrnasfer', initialWidth: 150,sortable: true ,hideDefaultActions: true},
    /*{ label: 'Handover Phase', fieldName: 'handoverPhaseGroup', initialWidth: 150,sortable: true ,hideDefaultActions: true},
    { label: 'Handover Phase Date', fieldName: 'handoverPhaseDate', initialWidth: 150,sortable: true ,hideDefaultActions: true},
    { label: 'HC letter Date', fieldName: 'hcLetter', type: 'date', initialWidth: 150,sortable: true ,hideDefaultActions: true},
    { label: 'HP letter Date', fieldName: 'hpLetter', type: 'date' , initialWidth: 150,sortable: true,hideDefaultActions: true },
    { label: 'HO letter Date', fieldName: 'choDate', type: 'date', initialWidth: 150 ,sortable: true ,hideDefaultActions: true} , */
    { label: 'SR Status', fieldName: 'srStatus' , initialWidth: 200,sortable: true ,hideDefaultActions: true},
    { label: 'HO Agent', fieldName: 'hoAgent' , initialWidth: 150,sortable: true ,hideDefaultActions: true},
    { label: 'KAR', fieldName: 'kra' , initialWidth: 150,sortable: true ,hideDefaultActions: true},
    {
        type: 'action',
        typeAttributes: { rowActions: actions },
    }
];



export default class HandoverSetup extends NavigationMixin(LightningElement) {
    //Get Opportunity or Lead Ids
   
    showModal=false;
    actionName;
    isLoading = true;
    projectList;
    selectedProject;
    buildingList=[];
    selectedBuilding;
    @track unitDataTable;
    @track bedroomFilterList=[];
    phasingProcess;
    karProcess;
    selectedUnits=[];
    karUserList=[];
    financeProfile=false;
    //rowOffset=0;
    columns = columns;
  
    @track isButtonVisible = false;
    disableBuildingSection=true;
    disableBedroomSection=true;
    searchValue;
    timer;

    searchValue;

    //harsh@aldar added for ReassignKAR
    @track value;
    @track checkForHandOverAssign;
    @track selectedUnitIds;
    @track filterKarUserList;

    searchUnitHandlar(event){
        //this.isLoading = true;  
        console.log('*** searchUnitHandlar ***',event.target.value);
        this.searchValue=event.target.value;

        /*
       if(this.unitDataTableAll && (searchValue || searchValue=='')){
        this.unitDataTable=this.unitDataTableAll ;
        this.isLoading = false;  
       }
       window.clearTimeout(this.timer);
       this.timer = window.setTimeout(()=>{
       this.searchLogic(searchValue);
     }, 800);
     */

      
    }

    searchLogic(searchKey){
        if(this.unitDataTableAll && this.unitDataTableAll.length>0){
            let filteredData=this.unitDataTableAll.filter( (unitElement)=> unitElement.unitName.toLowerCase().includes(searchKey.toLowerCase()));
            this.unitDataTable=filteredData;
            this.isLoading = false; 
        }
        this.isLoading = false; 
    }


    /* Default methods */
    connectedCallback() {
        this.populateProjects();
    }
    renderedCallback() {
      
    }
    disconnectedCallback() {

    }

    @wire(getRecord, {
        recordId: strUserId,
        fields: [PROFILE_NAME_FIELD]
    }) wireuser({
        error,
        data
    }) {
        if (error) {
            this.error = error ; 
        } else if (data) {
            this.financeProfile = (data.fields.Profile.value.fields.Name.value==='Finance Team'  )
        }
    }

    /* getters */
    
    get disableActions() {
        return (this.selectedUnits < 1 ||  this.financeProfile);
    }
    get disableActionsFinance() {
        return (this.selectedUnits < 1 || !this.financeProfile);
    }
    get srStatusFilterList() {
        return [
            { label: 'None', value: '' },
            { label: 'Offered By Projects', value: 'Offered By Projects' },
            { label: 'Released by QA', value: 'Released by QA' },
            { label: 'Pending Handover Completion Letter', value: 'Pending Handover Completion Letter' },
            { label: 'Pending Handover Phasing', value: 'Pending Handover Phasing' },
            { label: 'Pending Handover Phasing Letter', value: 'Pending Handover Phasing Letter' },
            { label: 'Pending KAR Assignment / Billing', value: 'Pending KAR Assignment / Billing' },
            { label: 'Pending Finance Verification', value: 'Pending Finance Verification' },
            { label: 'Finance Verification Completed', value: 'Finance Verification Completed' },
            { label: 'Pending Home Orientation Letter', value: 'Pending Home Orientation Letter' },
            { label: 'Pending Customer Home Orientation Appointment', value: 'Pending Customer Home Orientation Appointment' },
            { label: 'Pending Home Orientation', value: 'Pending Home Orientation' },
            { label: 'Pending Ready for Occupancy', value: 'Pending Ready for Occupancy' },
            { label: 'Pending Title Deed Registration', value: 'Pending Title Deed Registration' },
            { label: 'Pending PMA Registration', value: 'Pending PMA Registration' },
            { label: 'Pending Customer Utility Transfer', value: 'Pending Customer Utility Transfer' },
            { label: 'Pending Customer Key Handover Appointment', value: 'Pending Customer Key Handover Appointment' },
            { label: 'Pending Key Handover', value: 'Pending Key Handover' },
            { label: 'Handover Completed', value: 'Handover Completed' }
            
        ];
    }
    /* Apex Call Methods */

    
    handleMenuAction(event) {
        this.isLoading=true;
        this.actionName = event.target.name;
        //for button menu
        if(!this.actionName || this.actionName=='' ){
            this.actionName = event.detail.value;
        }
        if(this.actionName == 'HANDOVERACTION_CREATESR'){
            this.createServiceRequest();
        }else if(this.actionName == 'HANDOVERACTION_UPDATEGROUP' || this.actionName == 'HANDOVERACTION_ASSIGN_KAR'){
            this.phasingProcess = (this.actionName == 'HANDOVERACTION_UPDATEGROUP');
            this.karProcess = (this.actionName == 'HANDOVERACTION_ASSIGN_KAR');
            //harsh@aldar added variable for ReassignKAR
            this.checkForHandOverAssign = true;
            this.openModal();
            this.isLoading=false;
        }else if(this.actionName == 'HANDOVERACTION_SEND_HC' || this.actionName == 'HANDOVERACTION_SEND_HP' || this.actionName == 'HANDOVERACTION_SEND_HO' ){
            this.sendLetterAction();
        }else if(this.actionName == 'HANDOVERACTION_FINANCE_VERIFICATION'){
            this.performFinanceVerificationAction();
        }
        // harsh@aldar added for ReassignKAR
        else if(this.actionName == 'HANDOVERACTION_REASSIGN_KAR'){
            this.karProcess = (this.actionName == 'HANDOVERACTION_REASSIGN_KAR');
            this.checkForReassignKAR = true;
            this.checkForHandOverAssign = false;
            this.openModal();
            this.isLoading=false;
        }

        //this.openModal();
        
    }
   
    /*
    refreshUI(){
        let yearSelection = this.template.querySelector(".yearSelection");
        let securityDeposit = this.template.querySelector(".securityDeposit");

        if(yearSelection){
            yearSelection.value=this.selectedYearForBooking;
            securityDeposit.value = this.securityDeposit;
            this.template.querySelector(".discountPercetnage").value =  this.discountPercetnage;
            this.template.querySelector(".scApplicable").checked = this.scApplicable;
            this.template.querySelector(".hmApplicable").checked = this.hmApplicable;
            this.refreshUIFlag=false;
        }
    }*/
    /*
    reselectUnits(){
        let tempTable = JSON.parse(JSON.stringify(this.unitDataTable));
        this.unitDataTable=[];
        for (let i = 0; i < tempTable.length; i++) {
            tempTable[i].isSelected = this.selectedUnits[tempTable[i].unitDetails.Id] ? this.selectedUnits[tempTable[i].unitDetails.Id].selectionStatus :false;
        }
        this.unitDataTable=tempTable;
    }*/

    @wire(getKARList)
    getkarData({ error, data }) {
        if (data) {
            this.karUserList = data;
            
        } else if (error) {
            this.karUserList = undefined;
        }
    }

   

    populateProjects() {
        getAllProjects()
            .then(data => {
                this.unitDataTable = undefined;
                this.projectList = data;
                //this.projectList.push( {label:'ALL', value:'ALL'});
               // this.projectList.splice(0, 0, {label:'ALL', value:'ALL'});
                if(! this.selectedProject){
                   // this.selectedProject= (data && data[0] && data[0].value) ? data[0].value : '';
                }
                if (this.selectedProject) {
                   //c/salesOrderSubStatusthis.populateBuildings();
                } else {
                    this.isLoading = false;
                }

            })
            .catch(error => {
                // console.log('Unable to fetch Project data ==>'+ JSON.stringify(error));
                this.projectList = undefined;
                this.isLoading = false;
            });
    }

    populateBuildings() {
        //this.projectToProjectBudget();
        getAllBuildings({ projectId: this.selectedProject })
            .then(data => {
               // this.unitDataTable = undefined;                
               // this.buildingList.concat(data);
                this.buildingList=[...data];
                //this.buildingList.push({label:'ALL', value:'ALL'});
               // this.selectedBuilding = (data && data[0] && data[0].value) ? data[0].value : '';
                this.isLoading = false;
                //this.populateUnitData();
            })
            .catch(error => {
                // console.log('Unable to fetch Building data ==>'+ JSON.stringify(error));
                this.buildingList = undefined;
                this.isLoading = false;
            });
    }

    previousStatus='';
    PreviousProject='';
    unitDataTableAll;
    previousBuildingSection;

    populateUnitData() {
        this.isLoading = true;  
        let bedroom = this.template.querySelector(".bedroom").value;
        let floor='';
        let srStatus = this.template.querySelector(".srStatus").value;
        let projectId = this.template.querySelector(".project").value;
        let selectedBuildingId=this.selectedBuilding;
       // console.log(this.selectedBuilding + '---' + srStatus);

        
        if((!this.searchValue  ||  this.searchValue=='') && (!projectId || projectId=='')){
            const evt = new ShowToastEvent({
                title: 'Manidatory',
                message: ' Please enter project ',
                variant: 'error',
            });
             this.dispatchEvent(evt);
            this.isLoading = false;
            return;
        }
        
        if((!this.searchValue  ||  this.searchValue=='') && ((srStatus && this.previousStatus==srStatus) && (this.PreviousProject!='' && this.PreviousProject==projectId) && (this.selectedBuilding==this.previousBuildingSection)) ){
            if( this.unitDataTableAll && this.unitDataTableAll.length>0){
               // console.log('*** unitDataTableAll **',JSON.stringify(this.unitDataTableAll));
                let unitDataTableFilter=[];

                if(bedroom && bedroom=='ALL'){
                    let bedroom = this.template.querySelector(".bedroom").value='';
                    //this.disableBedroomSection=true;
                    this.unitDataTable=this.unitDataTableAll;
                    this.isLoading = false;
                    return;
                }

                if(!bedroom){
                     unitDataTableFilter= this.unitDataTableAll.filter(unitElement=>{
                        return unitElement.projectId==projectId && unitElement.buildingId==this.selectedBuilding;
                      })
                }

                
                if(bedroom){
                     unitDataTableFilter= this.unitDataTableAll.filter(unitElement=>{
                       // console.log('*** numberOfBedrooms ****',unitElement.numberOfBedrooms);
                        return unitElement.projectId==projectId && unitElement.buildingId==this.selectedBuilding
                               && unitElement.numberOfBedrooms==bedroom;
                      })
                }              
                 
               this.unitDataTable=unitDataTableFilter;
               this.isLoading = false;
               const evt = new ShowToastEvent({
                title: 'Data Load Complited',
                message: 'Data Load Complited',
                variant: 'success',
            });
             this.dispatchEvent(evt);
               return;
             }
        }
    
        this.previousStatus=srStatus;
        this.PreviousProject=projectId;
        this.previousBuildingSection=this.selectedBuilding;

        this.unitDataTable=[];
        this.unitDataTableAll=[];
        getUnitDetails({ buildingsId: this.selectedBuilding+'' , bedroom : bedroom , floor : floor , srStatus : srStatus,projectId:projectId, searchValue:this.searchValue})
            .then(data => {
                //this.unitDataTable = data;
               // console.log('**** getUnitDetails Data ***',JSON.stringify(data));
                if (data.length <= 0) {
                    const evt = new ShowToastEvent({
                        title: 'Units',
                        message: 'No unit available for selected filter criteria ',
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                }else{
                    try{
                    if(projectId && projectId!=''){
                        this.disableBuildingSection=false;
                    }
                    
                    //this.disableBedroomSection=false;
                    let buildingoptions=[];
                    this.bedroomFilterList=[];
                    for (let i = 0; i < data.length; i++) {

                        let inputobj={};
                        inputobj.unitId= data[i].unitDetails.Id;
                        inputobj.unitName=data[i].unitDetails.Name;
                        inputobj.salesOrderName=data[i].soDetails ? data[i].soDetails.Name : '';
                        if(data[i].unitDetails.BuildingSectionName__r.AnticipatedCompletionDate__c){
                            inputobj.acdDate= data[i].unitDetails.BuildingSectionName__r.AnticipatedCompletionDate__c;
                        } 
                        if(data[i].srDetails && data[i].srDetails.HandoverDetail__c){
                            inputobj.offeredDate= data[i].srDetails.HandoverDetail__r.UnitOfferedDate__c;
                        }
                        if(data[i].srDetails && data[i].srDetails.HandoverDetail__c){
                            inputobj.qaOfferedDate= data[i].srDetails.HandoverDetail__r.QADesnaggingDate__c;
                        }
                        //'choDate': data[i].srDetails && data[i].srDetails.HandoverDetail__c ?data[i].srDetails.HandoverDetail__r.CHODate__c: undefined,
                        if(data[i].srDetails && data[i].srDetails.HandoverDetail__c){
                            inputobj.hcLetter=data[i].srDetails.HandoverDetail__r.HandoverCompletionLetterDate__c;
                        }
                        if(data[i].srDetails && data[i].srDetails.HandoverDetail__c ){
                            inputobj.hpLetter=data[i].srDetails.HandoverDetail__r.HandoverPhasingLetterDate__c;
                        }
                        inputobj.srName=data[i].srDetails ?data[i].srDetails.Name: '';
                        inputobj.srHeighlight= data[i].srDetails ? '':'slds-is-edited';
                        inputobj.srStatus=data[i].srDetails && data[i].srDetails.HandoverDetail__c ?data[i].srDetails.HandoverDetail__r.Stage__c: '';
                        inputobj.handoverPhaseGroup=data[i].srDetails && data[i].srDetails.HandoverDetail__c?data[i].srDetails.HandoverDetail__r.HandoverPhaseGroup__c: '';
                        if(data[i].srDetails && data[i].srDetails.HandoverDetail__c){
                            inputobj.handoverPhaseDate=data[i].srDetails.HandoverDetail__r.HandoverPhaseDate__c
                        }
                        inputobj.kra=data[i].srDetails && data[i].srDetails.HandoverDetail__c && data[i].srDetails.HandoverDetail__r.KAR__r ? data[i].srDetails.HandoverDetail__r.KAR__r.Name: '',
                        inputobj.customerName= data[i].soDetails ? data[i].soDetails.Account__r.Name  : '';
                         if(data[i].srDetails){
                            inputobj.srId= data[i].srDetails.Id;
                         }
                         if(data[i].srDetails && data[i].srDetails.HandoverDetail__c){
                            inputobj.hoId= data[i].srDetails && data[i].srDetails.HandoverDetail__c;
                         }
                        inputobj.soId=data[i].soDetails ? data[i].soDetails.Id:'';
                        if(data[i].srDetails && data[i].srDetails.HandoverDetail__c){
                            inputobj.qaDesnagDate= data[i].srDetails.HandoverDetail__r.QADesnaggingDate__c;
                        }
                        if(data[i].srDetails && data[i].srDetails.HandoverDetail__c){
                            inputobj.choDate=data[i].srDetails.HandoverDetail__r.CHODate__c;
                        }
                        inputobj.appointment= (data[i].srDetails && data[i].srDetails.HandoverDetail__c && data[i].srDetails.HandoverDetail__r.CustomerSnaggingAppointment__c);
                        if(data[i].srDetails && data[i].srDetails.HandoverDetail__c){
                            inputobj.rfoDate= data[i].srDetails.HandoverDetail__r.RFODate__c;
                        }
                        inputobj.hoAgent= data[i].srDetails && data[i].srDetails.HandoverDetail__c && data[i].srDetails.HandoverDetail__r.HandoverAgent__r ? data[i].srDetails.HandoverDetail__r.HandoverAgent__r.Name: '';
                        inputobj.isPlot=data[i].srDetails ? data[i].srDetails.isPlot__c : false;
                        inputobj.isRTO=data[i].srDetails ? data[i].srDetails.isRTOHandover__c : false;
                        inputobj.isRTO=data[i].srDetails ? data[i].srDetails.isRTOHandover__c : false;
                        inputobj.projectId=data[i].unitDetails ? data[i].unitDetails.Project__c : '';
                        inputobj.buildingId=data[i].unitDetails ? data[i].unitDetails.BuildingSectionName__c : '';
                        inputobj.unitId=data[i].unitDetails ? data[i].unitDetails.Id : '';
                        inputobj.numberOfBedrooms=data[i].unitDetails ? data[i].unitDetails.NumberOfBedrooms__c : '';
                        this.unitDataTable.push(inputobj);
                      
                        if(this.selectedBuilding && this.selectedBuilding!=''){
                            if(data[i].unitDetails.NumberOfBedrooms__c && data[i].unitDetails.NumberOfBedrooms__c!='' && this.bedroomFilterList.findIndex((item) => item.label === data[i].unitDetails.NumberOfBedrooms__c) === -1 ){
                                this.bedroomFilterList.push({ label: data[i].unitDetails.NumberOfBedrooms__c, value: data[i].unitDetails.NumberOfBedrooms__c });
                            }
                        }
                    }
                }catch(e){
                    console.log(Json.stringify(e));
                }
                }
                this.unitDataTable = [...this.unitDataTable];
                this.unitDataTableAll=[...this.unitDataTable];
                this.bedroomFilterList = [...this.bedroomFilterList];
                this.bedroomFilterList.splice(0, 0, {label:'ALL', value:'ALL'});
                this.isLoading = false;
                if(this.selectedBuilding && this.selectedBuilding!=''){
                    this.disableBedroomSection=false;
                }           
            })
            .catch(error => {
                console.log('Unable to fetch Unit data ==>'+ JSON.stringify(error));
                this.isLoading = false;

            });
    }

    clearFliters(){
        
        this.template.querySelector(".bedroom").value='';
        this.template.querySelector(".srStatus").value='';
        this.template.querySelector(".project").value='';
        this.template.querySelector(".buildingSection").value='';
        this.searchValue='';
        this.selectedBuilding='';
        this.sortedBy=undefined;
        this.unitDataTable = [];
        this.unitDataTableAll=[];
        this.bedroomFilterList=[];
        this.buildingList=[];
        this.disableBuildingSection=true;
        this.disableBedroomSection=true;
        //this.populateUnitData();
    }

    /* Handler Methods */
    handleProjectChange(event) {
        //this.unitDataTable = undefined;
       // this.isLoading = true;
        this.selectedProject = event.detail.value;
        console.log('*** selectedProject ***'+this.selectedProject);
        this.disableBuildingSection=true;
        this.disableBedroomSection=true;
        this.selectedBuildin='';
        this.searchValue='';
        this.template.querySelector(".bedroom").value='';
        this.populateBuildings();
        //this.selectedUnits={};
        //this.populateBuildings();
    }

    handleStstusChange(event){
        //this.selectedProject ='';
       // this.selectedBuilding='';
       // this.disableBuildingSection=true;
       // this.disableBedroomSection=true;
       // this.template.querySelector(".bedroom").value='';
        
    }

    handleBuildingChange(event) {
       // this.unitDataTable = undefined;
       // this.isLoading = true;
        this.selectedBuilding = event.detail.value;
        this.searchValue='';
      //  this.disableBuildingSection=true;
        if(this.selectedBuilding!=''){
            this.disableBedroomSection=false;
        }
        
        //this.populateUnitData();
    }
    
    handleRowSelect(event) {

        this.isLoading = true;
        this.selectedUnits = event.detail.selectedRows;
        this.isLoading = false;
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'sr_details':
                this.navigateToDetails(row.srId);
                break;
            case 'so_details':
                this.navigateToDetails(row.soId);
                break;
            case 'unit_details':
                this.navigateToDetails(row.unitId);
                break;
            case 'ho_details':
                this.navigateToDetails(row.hoId);
                break;
            case 'SOA_details':
                this.navigateToSOA(row.soId);
                break;
            case 'ERP_SOA_details':
                    getSRsrDocID({srId : row.srId})
                    .then(data => {
                        this.navigateToDetails(data);
                    })
                    .catch(error => {
                     console.log('ERP SOA');
                    })
                break;
            default:
        }
    }

    navigateToDetails(recordId){
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view',
            },
        }).then(url => {
            window.open(url, "_blank");
        });
    }
    navigateToSOA(recordId){
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: '/apex/StatementOfAccountDocument?id=' + recordId
            },
        }).then(url => {
            window.open(url, "_blank");
        });
    }

    performFinanceVerificationAction(){
        let srToProcess = [];
        for (let i = 0; i < this.selectedUnits.length; i++) {
            if(!this.selectedUnits[i].srId){
                const evt = new ShowToastEvent({
                    title: 'Warning',
                    message: 'No Service request found for selected unit',
                    variant: 'warning',
                });
                this.dispatchEvent(evt);
                this.isLoading = false;
                return;
            }else if(this.selectedUnits[i].srStatus !='Pending Finance Verification' ){
                const evt = new ShowToastEvent({
                    title: 'Warning',
                    message: 'Only SRs with Pending Finance Verification status can be updated',
                    variant: 'warning',
                });
                this.dispatchEvent(evt);
                this.isLoading = false;
                return;
            }
            srToProcess.push(this.selectedUnits[i].srId);
        }
        performFinanceVerification({srIds : srToProcess })
        .then(data => {
            if(data =='success'){
                const evt = new ShowToastEvent({
                    title: 'Success',
                    message: 'Verification completed succssefully!',
                    variant: 'success',
                });
                this.dispatchEvent(evt);
                this.isLoading = false;
            }else{
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: data,
                    variant: 'error',
                });
                this.dispatchEvent(evt);
                this.isLoading = false;
            }
        })
        .catch(error => {
            const evt = new ShowToastEvent({
                title: 'Error',
                message: error,
                variant: 'error',
            });
            this.dispatchEvent(evt);
            this.isLoading = false;
        })
    }

    sendLetterAction(){
        let srToProcess = [];
        for (let i = 0; i < this.selectedUnits.length; i++) {
           
            if(!this.selectedUnits[i].srId){
                const evt = new ShowToastEvent({
                    title: 'Warning',
                    message: 'No Service request found for selected unit',
                    variant: 'warning',
                });
                this.dispatchEvent(evt);
                this.isLoading = false;
                return;
            }else if(this.actionName == 'HANDOVERACTION_SEND_HC' && this.selectedUnits[i].qaDesnagDate!=undefined && !this.selectedUnits[i].isPlot){
                const evt = new ShowToastEvent({
                    title: 'Warning',
                    message: 'QA Desnagging action must be completed before sending HC letters' + this.selectedUnits[i].qaDesnagDate,
                    variant: 'warning',
                });
                this.dispatchEvent(evt);
                this.isLoading = false;
                return;
            }else if(this.actionName == 'HANDOVERACTION_SEND_HP' && (this.selectedUnits[i].handoverPhaseGroup ==undefined || this.selectedUnits[i].handoverPhaseGroup =='' || this.selectedUnits[i].handoverPhaseDate==undefined) ){
                const evt = new ShowToastEvent({
                    title: 'Warning',
                    message: 'Phasing action must be completed before sending phasing letters',
                    variant: 'warning',
                });
                this.dispatchEvent(evt);
                this.isLoading = false;
                return;
            }else if(this.actionName == 'HANDOVERACTION_SEND_HO' &&  this.selectedUnits[i].srStatus !='Finance Verification Completed' ){
                const evt = new ShowToastEvent({
                    title: 'Warning',
                    message: 'Finance Verification must be completed before sending Home orientation letters',
                    variant: 'warning',
                });
               // this.dispatchEvent(evt);
               // this.isLoading = false;
               // return;
            }else if((this.actionName == 'HANDOVERACTION_SEND_HC' && this.selectedUnits[i].hcLetter!=undefined) || (this.actionName == 'HANDOVERACTION_SEND_HP' && this.selectedUnits[i].hpLetter!=undefined) || (this.actionName == 'HANDOVERACTION_SEND_HO' && this.selectedUnits[i].choDate!=undefined)){
                const evt = new ShowToastEvent({
                    title: 'Warning',
                    message: 'Action already performed for '+this.selectedUnits[i].unitName +' Unit',
                    variant: 'warning',
                });
                this.dispatchEvent(evt);
                this.isLoading = false;
                return;
            }else if(this.selectedUnits[i].isRTO && (this.actionName == 'HANDOVERACTION_SEND_HP' || this.actionName == 'HANDOVERACTION_SEND_HC' ) ){
                const evt = new ShowToastEvent({
                    title: 'Warning',
                    message: 'Action not supported for RTO '+this.selectedUnits[i].unitName +' Unit',
                    variant: 'warning',
                });
                this.dispatchEvent(evt);
                this.isLoading = false;
                return;
            } 
            srToProcess.push(this.selectedUnits[i].srId);
        }
        sendLetter({srIds : srToProcess , actionName : this.actionName})
        .then(data => {
            const evt = new ShowToastEvent({
                title: 'Success',
                message: 'Action scheduled succssefully!',
                variant: 'success',
            });
            this.populateUnitData();
            this.dispatchEvent(evt);
            this.isLoading = false;
        })
        .catch(error => {
            const evt = new ShowToastEvent({
                title: 'Error',
                message: error,
                variant: 'error',
            });
            this.dispatchEvent(evt);
            this.isLoading = false;
        })
        
    }

    createServiceRequest() {
        let unitsToProcess = [];
        for (let i = 0; i < this.selectedUnits.length; i++) {
            unitsToProcess.push(this.selectedUnits[i].unitId);
        }
        createHandoverSR({unitIds : unitsToProcess})
            .then(data => {
                if(data =='success'){
                    const evt = new ShowToastEvent({
                        title: 'Success',
                        message: 'Service Request created successfully for selected units',
                        variant: 'success',
                    });
                    this.dispatchEvent(evt);
                    this.populateUnitData();
                }else{
                    const evt = new ShowToastEvent({
                        title: 'Error',
                        message: data,
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                    this.isLoading = false;
                }
                
            })
            .catch(error => {
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: error,
                    variant: 'error',
                });
                this.dispatchEvent(evt);
                this.isLoading = false;
            })

    }
    updatePhasingGroup() {
        let phaseGroup = (this.template.querySelector(".phaseGroup") && this.template.querySelector(".phaseGroup").value) ? this.template.querySelector(".phaseGroup").value :undefined;
        let phaseDate = (this.template.querySelector(".phaseDate") && this.template.querySelector(".phaseDate").value) ? new Date(this.template.querySelector(".phaseDate").value): undefined;
        let selectedKar = ( this.template.querySelector(".selectedKar") && this.template.querySelector(".selectedKar").value) ? this.template.querySelector(".selectedKar").value: undefined;
        let expectedHandoverDate = (this.template.querySelector(".expectedHandoverDate") && this.template.querySelector(".expectedHandoverDate").value) ? new Date(this.template.querySelector(".expectedHandoverDate").value): undefined;
        if(!phaseGroup && this.phasingProcess){
            const evt = new ShowToastEvent({
                title: 'Warning',
                message: 'Handover Phase Group Name is required',
                variant: 'warning',
            });
            this.dispatchEvent(evt);
            this.isLoading = false;
            return;
        }
        if(!selectedKar && this.karProcess){
            const evt = new ShowToastEvent({
                title: 'Warning',
                message: 'KAR is required',
                variant: 'warning',
            });
            this.dispatchEvent(evt);
            this.isLoading = false;
            return;
        }

        let srToProcess = [];
        for (let i = 0; i < this.selectedUnits.length; i++) {
            if(!this.selectedUnits[i].srId){
                const evt = new ShowToastEvent({
                    title: 'Warning',
                    message: 'No Service request found for selected unit',
                    variant: 'warning',
                });
                this.dispatchEvent(evt);
                this.isLoading = false;
                return;
            }
            srToProcess.push(this.selectedUnits[i].srId);
        }
        this.closeModal();
        updateSRDetails({srIds : srToProcess,phasingDate : phaseDate ,groupName :phaseGroup , karID : selectedKar , expectedHandoverDate : expectedHandoverDate})
            .then(data => {
                if(data =='success'){
                    const evt = new ShowToastEvent({
                        title: 'Success',
                        message: 'Service Request successfully updated',
                        variant: 'success',
                    });
                    this.dispatchEvent(evt);
                    this.populateUnitData();
                }else{
                    const evt = new ShowToastEvent({
                        title: 'Error',
                        message: data,
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                    this.isLoading = false;
                }
                
            })
            .catch(error => {
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: error,
                    variant: 'error',
                });
                this.dispatchEvent(evt);
                this.isLoading = false;
            })
    }
    openModal() {
        this.showModal = true;
    }
    closeModal() {
        this.showModal = false;
    }
    submitDetails(event) {
        this.isLoading=true;
        if(this.phasingProcess || this.karProcess && this.checkForHandOverAssign){
            this.updatePhasingGroup();
        }
        // harsh@aldar added condition for ReassignKAR
        else if(this.checkForReassignKAR && this.value){
            this.reAssignKARToServiceRequests(this.selectedUnitIds,this.value);
        }else{
            const evt = new ShowToastEvent({
                title: 'Warning',
                message: 'KAR is required',
                variant: 'warning',
            });
            this.dispatchEvent(evt);
            this.isLoading = false;
            return;
        }
    }

    //Sorting Logic
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy;

    // Used to sort 
    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                  return primer(x[field]);
              }
            : function (x) {
                  return x[field];
              };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    
    }

    onHandleSort(event) {
        
       
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.unitDataTable];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.unitDataTable = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    //harsh@aldar added handleChange method for ReassignKAR
    handleChange(event){
        this.selectedUnitIds = this.selectedUnits.map(row => row.srId);
        this.value = event.target.value;
    }

    //harsh@aldar added  method for ReassignKAR
    reAssignKARToServiceRequests(selectedUnitIds,value){
        this.closeModal();
        reAssignKARToServiceRequests({selectedUnitIds:selectedUnitIds, newKARId:value })
            .then(data => {
                if(data =='KAR ReAssignment Successfully'){
                    this.value = false;
                    const evt = new ShowToastEvent({
                        title: 'Success',
                        message: 'KAR ReAssignment Successfully',
                        variant: 'success',
                    });
                    this.dispatchEvent(evt);
                    this.populateUnitData();
                    
                }else{
                    const evt = new ShowToastEvent({
                        title: 'Error',
                        message: data,
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                    this.isLoading = false;
                }
                
            })
            .catch(error => {
                console.log(error);
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: error,
                    variant: 'error',
                });
                this.dispatchEvent(evt);
                this.isLoading = false;
            })
    }
}