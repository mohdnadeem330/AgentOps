import { LightningElement,api,wire,track } from 'lwc';
import getAllAgency from '@salesforce/apex/CommunicationController.getAllAgency';
import getReletedCommunicationRecords from '@salesforce/apex/CommunicationController.getReletedCommunicationRecords';
import getRelatedUsers from '@salesforce/apex/CommunicationController.getRelatedUsers';
import updateUserSelection from '@salesforce/apex/CommunicationController.updateUserSelection';
import getExistingCDL from '@salesforce/apex/CommunicationController.getExistingCDL';
import reparentCDL from '@salesforce/apex/CommunicationController.reparentCDL';
// Added By Moh Sarfaraj for BPE-79 starts
import sendToSpecificEmirate from '@salesforce/apex/CommunicationController.sendToSpecificEmirateAllAgencies';
import sendEmailBrokerFilterCommunication from '@salesforce/apex/CommunicationController.sendEmailBrokerFilterCommunication';
// Added By Moh Sarfaraj for BPE-79 end
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; 
// Added by Moh Sarfaraj for BPE-113 starts
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import AGENT_CATEGORY from "@salesforce/schema/Contact.AgentCategory__c";
// Added by Moh Sarfaraj for BPE-113 end
import getBrokerDocBanners from '@salesforce/apex/CommunicationController.getBrokerDocBanners';

import USER_OBJECT from "@salesforce/schema/User";
import TEAM_FIELD from "@salesforce/schema/User.Team__c";

export default class Communication extends NavigationMixin(LightningElement) {
    @api recordId;
    // updated By Moh Sarfaraj for BPE-79, BPE-113
    @track
    activeSections=['CommunicationType','MessageDetails','CommunicationPreference','AgencyDetails','AgentDetails', 'CommunicationByEmail', 'AgentCategory'];
    isEmailCommincation=false;
    isLoading=true;
    isPublished=false;
    initLoad=true;
    @track uploadedFiles=[];
    @track complaiance=false;
    agencyList;
    @track selectedAgencies=[];

    agentList
    @track selectedAgents=[]; selectAgencyCountry = ''; countryOptions = [];

    //Added By Moh Sarfaraj to Send to specific Emirate - Start BPE-62
    isSendToSpecificEmirate = false;
    bannerValues = [];
    selectedBannerId;
    //Added By Moh Sarfaraj to Send to specific Emirate - Start BPE-62

    // Added by Moh Sarfaraj for BPE-113 starts
    @track brokerAgentRecordTypeId;
    @track agentCategoryPicklistValues;
    @track objectNameToGetRecordTypes = 'Contact';
    
    @wire(getObjectInfo, { objectApiName: '$objectNameToGetRecordTypes' })
    getObjectInfo({ error, data }) {
        if (data) {
            for(let key in data.recordTypeInfos) {
                if(data.recordTypeInfos[key].name === 'Broker Agent'){
                    this.brokerAgentRecordTypeId = data.recordTypeInfos[key].recordTypeId;
                }
            }
        }
        else if (error) {
            console.log('Error while get record types');
            this.brokerAgentRecordTypeId = undefined;
        }
    }

    @wire(getPicklistValues, { recordTypeId: "$brokerAgentRecordTypeId", fieldApiName: AGENT_CATEGORY })
    picklistResults({ error, data }) {
        if (data) {
            this.agentCategoryPicklistValues = [];
            for(let key in data.values){
                this.agentCategoryPicklistValues.push({
                    label : data.values[key].label, 
                    value : data.values[key].value
                })
            }
        } else if (error) {
            this.agentCategoryPicklistValues = [];
        }
    }
    // Added by Moh Sarfaraj for BPE-113 end

    // Added by Moh Sarfaraj for BPM-533 starts
    userDefaultRecordTypeId = '012000000000000AAA'; teamField; teamFieldSelected = '';
    @wire(getPicklistValues, { recordTypeId: "$userDefaultRecordTypeId", fieldApiName: TEAM_FIELD })
    getPicklistValuesResults({ error, data }) {
        if (data) {
            this.teamField = data.values;
        } else if (error) {
            this.teamField = undefined;
        }
    }

    handleTeamChange(event){
        this.teamFieldSelected = event.target.value;
    }
    // Added by Moh Sarfaraj for BPM-533 End

    // Added by Tharun
    @wire(getBrokerDocBanners, {})
    getBrokerDocBannersValues ({error, data}) {
        if (error) {
            // TODO: Error handling
        } else if (data) {
            // TODO: Data handling
            data.forEach(element => {
                this.bannerValues.push({ label: element.Name, value: element.Id });
            });
        }
    }

    handleBannerValChange(event){
        this.selectedBannerId = event.detail.value;
    }

    // Added by Tharun

    get hasRecordId() {
        return (this.recordId != '' && this.recordId !=null && this.recordId != undefined );
    }

    get disableAgentSelection() { // updated By Moh Sarfaraj for BPE-79, BPE-167
        return (this.sendAllFlag || this.isPublished || this.isSendToSpecificEmirate || this.sendByEmail || this.sendClassified || this.isAdminOwnerComm);
    }

    get regionValues() {
        return [
            { label: 'Domestic', value: 'Domestic' },
            { label: 'International', value: 'International' },
        ];
    }
    get emiratesValues() {
        return [
            { label: 'Ajman', value: 'Ajman' },
            { label: 'Abu Dhabi', value: 'Abu Dhabi' },
            { label: 'Dubai', value: 'Dubai' },
            { label: 'Fujairah', value: 'Fujairah' },
            { label: 'Ras Al Khaimah', value: 'Ras Al Khaimah' },
            { label: 'Sharjah', value: 'Sharjah' },
            { label: 'Umm Al Quwain', value: 'Umm Al Quwain' },
        ];
    }
    get showEmirates(){
        return  (this.regionVal && this.regionVal == 'Domestic');
    }
 
    // Added by Moh Sarfaraj BPE-502
    get showCountry(){
        return  (this.regionVal && this.regionVal == 'International');
    }
    
    count = 0;

    @wire(getAllAgency, {   regionFilter : '$regionVal',  emiratesFilter : '$emiratesVal', 
                            selectAgencyCountry : '$selectAgencyCountry', team : '$teamFieldSelected'
                        })
    getAllAgencyRecords({ error, data }) {

        this.isLoading = true;
        if (data) {
            let countryOption = [];
            
            if(this.regionVal == 'Domestic'){
                this.count = 0;
            }
            this.agencyList=[];
            for(let i=0; i<data.length ;i++){
                this.agencyList.push({ label: data[i].Name, value: data[i].Id });

                // Added by Moh Sarfaraj BPE-502
                if(this.showCountry && this.count === 0){
                    if(data[i].BillingCountry != null){
                        countryOption.push({ label: data[i].BillingCountry, value: data[i].BillingCountry })
                    }
                }
            }
            
            // Added by Moh Sarfaraj BPE-502
            if(this.showCountry && this.count === 0){
                const filteredCountryOptions = countryOption.reduce((acc, current) => {
                    const x = acc.find(item => item.label === current.label);
                    if (!x) {
                        return acc.concat([current]);
                    } else {
                        return acc;
                    }
                }, []);

                this.countryOptions = filteredCountryOptions.sort((a, b) => a.label.localeCompare(b.label));
                ++this.count;
            }
            this.isLoading = false;
        } else if (error) {
            this.agencyList=[];
            this.isLoading = false;
        }
    }

    regionVal='';
    emiratesVal='';
    handleRegionValChange(event){
        this.regionVal = event.target.value;
        this.emiratesVal ='';

        if(this.regionVal == 'International'){
            this.selectAgencyCountry = '';
        }
    }

    handleEmiratesValChange(event){
        this.emiratesVal = event.target.value;
    }
    handleTypeChange(event){
        this.isEmailCommincation= (event.target.value =='Email');
    }

    handleAgencyChange(event){
        this.selectedAgencies = event.detail.value;
        this.initAgentRecords();
        // Added by Moh Sarfaraj for BPE-113 
        this.selectedAgentCategory = '';
        this.isAgentCategory = false;
    }
    handleComplaiceChange(event){
        this.complaiance = event.detail.checked;
    }

    handleCountryChange(event){ // for international agencies
        this.selectAgencyCountry = event.detail.value;
        this.regionVal = 'International';
        this.emiratesVal = '';
    }
    
    initAgentRecords(){
        this.isLoading=true;
        getRelatedUsers({accountIds:  this.selectedAgencies })
        .then(data => {
            this.agentList=[];
            var newSelection=[];
            for(let i=0; i<data.length ;i++){
                this.agentList.push({ label: data[i].Contact.Name, value: data[i].Id });

                if(this.loadingAgenctsData && this.selectedAgents.findIndex((item) => item === data[i].Id) === -1){
                    this.selectedAgents.push(data[i].Id);
                    
                }
            }
            if(!this.loadingAgenctsData){
                this.loadingAgenctsData=true;
            }
            //this.selectedAgents =(newSelection.length >0 || !this.loadingAgenctsData)? newSelection : this.selectedAgents;
            
            /*if(this.selectedAgents.length>0){
                this.selectedAgents = [...this.selectedAgents];
            }*/
            this.isLoading=false;
        })
        .catch(error => {
            const evt = new ShowToastEvent({
                title: 'Error',
                message: 'Error while fetching data '+error,
                variant: 'error',
            });
            this.dispatchEvent(evt);
            this.isLoading=false;
        });
    }
    handleAgentChange(event){
        this.selectedAgents = event.detail.value;
    }
    handleSubmit(event){
        // Modified by Tharun for BPE-175
        this.isLoading=true;
        event.preventDefault();
        const fields = event.detail.fields;
        
        const All_Compobox_Valid = [...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, input_Field_Reference) => {
                input_Field_Reference.reportValidity();
                return validSoFar && input_Field_Reference.checkValidity();
            }, true);
 
        if(All_Compobox_Valid){
            this.isLoading=false;
            this.template.querySelector('lightning-record-edit-form').submit(fields);
        }else{
            this.isLoading=false;
            const evt = new ShowToastEvent({
                title   : 'Error',
                message : 'Complete the mandatory fields',
                variant : 'error'
            });
            this.dispatchEvent(evt);
        }
        // Modified by Tharun for BPE-175
    }

    handleSuccess(event){
        this.recordId= event.detail.id;
        this.isLoading=true;
        if(this.uploadedFiles.length > 0){
            
            reparentCDL({fileData : this.uploadedFiles  ,templateId : this.recordId })
            .then(data => {
            })
            .catch(error => {
                console.log(error);
            });
        }

        // Added By Moh Sarfaraj for BPE-79 starts
        if(this.sendByEmail){ 
            this.sendCommSpecificCustomEmails();
            
        }else if(this.sendClassified){
            this.classifiedBrokers();
        }else
        // Added By Moh Sarfaraj for BPE-79 end
        // Added By Moh Sarfaraj to Send to specific Emirate - Start BPE-62
        if(this.isSendToSpecificEmirate) {
            this.doSendToSelectedEmirate();
        } 
        // Added By Moh Sarfaraj for BPE-113
        else if(this.isAgentCategory && this.selectedAgentCategory){
            this.sendCommSelectedCategory();
        }// Added By Moh Sarfaraj for BPE-113
        // Added By Moh Sarfaraj for BPE-167
        if(this.isAdminOwnerComm){
            this.sendCommunicateToAdminAndOwners();
        }
        else{
            if(this.sendAllFlag || this.selectedAgents.length >0 ||this.selectedAgencies.length > 0 || this.template.querySelector(".testEmail").value){
                updateUserSelection({
                    templateId      : this.recordId , 
                    userIDs         : this.selectedAgents , 
                    acountIds       : this.selectedAgencies , 
                    sendAllFlag     : this.sendAllFlag ,
                    testEmail       : this.template.querySelector(".testEmail").value,
                    bannerId        : this.selectedBannerId
                }).then(data => {
                        const evt = new ShowToastEvent({
                            title: 'Success',
                            message: 'Record saved successfully',
                            variant: 'success',
                        });
                        this.dispatchEvent(evt);
                        this.isLoading=false;
                        getRecordNotifyChange([{recordId: this.recordId}]);
                        this.handleNavigation();
                    })
                    .catch(error => {
                        console.log(error);
                        const evt = new ShowToastEvent({
                            title: 'Error',
                            message: 'Error while storing data '+error,
                            variant: 'error',
                        });
                        this.dispatchEvent(evt);
                        this.isLoading=false;
                        this.handleNavigation();
                    });
            }else{
                
                this.recordSuccess();
            }
        }
    }

    //Send to specific Emirate - Start Added by Moh Sarfaraj BPE-62
    handleSendToSelectedEmirate(event) {
        this.isSendToSpecificEmirate = event.target.checked;
        // Added by Moh Sarfaraj for BPE-167
        this.sendByEmail = false;
        this.sendClassified = false;
        this.isAgentCategory = false;
        this.isAdminOwnerComm = false;
        this.sendAllFlag = false;
    }

    doSendToSelectedEmirate() {
        sendToSpecificEmirate({
            regionName      : this.regionVal,
            emirateName     : this.emiratesVal, 
            templateId      : this.recordId,
            testEmail       : this.template.querySelector(".testEmail").value,
            bannerId        : this.selectedBannerId
        })
        .then(result => {
            getRecordNotifyChange([{recordId: this.recordId}]);
            this.recordSuccess();
        })
        .catch(error => {
            console.log('error > ',error);
            const evt = new ShowToastEvent({
                title: 'Error',
                message: 'Error while storing data '+error,
                variant: 'error',
            });
            this.dispatchEvent(evt);
            this.isLoading=false;
            this.handleNavigation();
        });
    }
    //Send to specific Emirate - End Added by Moh Sarfaraj BPE-62

    handleAttachmentRemove(event){
        var tempFiles = [];
        for (let i = 0; i < this.uploadedFiles.length; i++) {
            if(event.target.name != this.uploadedFiles[i].documentId){
                tempFiles.push({'name':this.uploadedFiles[i].name , 'documentId':this.uploadedFiles[i].documentId } );
            }
            
        }
        this.uploadedFiles = tempFiles;
    }

    handleError(){
        
    }
    connectedCallback(){
        this.sendAllFlag=false;
    }
    loadingAgenctsData=true;
    handleLoad(){
        if(this.hasRecordId && this.initLoad){
            getReletedCommunicationRecords({recordId : this.recordId })
            .then(data => {
                this.sendAllFlag = data[0].MassCommunication__c;
                
                if(data[0].Communication__r && !this.sendAllFlag  ){
                    for(let i=0; i<data[0].Communication__r.length ;i++){
                        if(this.selectedAgencies.findIndex((item) => item === data[0].Communication__r[i].Agency__c) === -1){
                            this.selectedAgencies.push(data[0].Communication__r[i].Agency__c);
                        }
                        if(this.selectedAgents.findIndex((item) => item === data[0].Communication__r[i].Recipient__c) === -1){
                            this.selectedAgents.push(data[0].Communication__r[i].Recipient__c);
                        }
                    }

                }
                
                
                if(this.selectedAgencies.length > 0 && !this.sendAllFlag){
                    this.loadingAgenctsData=false;
                    this.initAgentRecords();
                    
                }
                this.isEmailCommincation = data[0].Type__c =='Email';
                this.isPublished =  data[0].Status__c =='Published';
                this.complaiance = data[0].Compliance__c;
                
            })
            .catch(error => {
                this.selectedAgencies = [];
                this.selectedAgents = [];
            });

            getExistingCDL({templateId : this.recordId })
            .then(data => {
                this.uploadedFiles=data;
            })
            .catch(error => {
                console.log(error)
                this.uploadedFiles = [];
            });
        }
        this.initLoad=false;
        this.isLoading=false;
    }

    handleNavigation(){
        if(this.hasRecordId){
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    objectApiName: 'CommunicationTemplate__c',
                    actionName: 'view'
                    
                }
            });
        }else{
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'CommunicationTemplate__c',
                    actionName: 'home'
                    
                }          
            });
        }
    }
    
    handleUploadFinished(event){
        for (let i = 0; i < event.detail.files.length; i++) {
            this.uploadedFiles.push({'name':event.detail.files[i].name , 'documentId':event.detail.files[i].documentId } )
        }
    }
    
    sendAllFlag=false;
    updateComminicationPreference(event){
        this.sendAllFlag = event.target.checked;
        // Added By Moh Sarfaraj for BPE-79 starts
        this.disableEmailInput = true;
        if(this.sendByEmail){
            this.sendByEmail = !event.target.checked
        }
        if(this.sendClassified){
            this.sendClassified = !event.target.checked
        }
        // Added By Moh Sarfaraj for BPE-79 end
        // Added By Moh Sarfaraj for BPE-167 starts 
        if(this.isAdminOwnerComm){
            this.isAdminOwnerComm = !event.target.checked
        }
        this.isSendToSpecificEmirate = false;
        // Added By Moh Sarfaraj for BPE-167 end

        // Added by Moh Sarfaraj for BPE-113 start
        this.selectedAgentCategory = '';
        this.isAgentCategory = false;
        // Added by Moh Sarfaraj for BPE-113 end

        if(!this.sendAllFlag){
            // updated By Moh Sarfaraj for BPE-79, BPE-113
            this.activeSections=['CommunicationType','MessageDetails','CommunicationPreference','AgencyDetails','AgentDetails', 'CommunicationByEmail', 'AgentCategory'];
        }else{
            this.selectedAgents=[];
            this.selectedAgencies=[];
        }
    }

    // Added By Moh Sarfaraj for BPE-79 starts
    sendByEmail = false;
    disableEmailInput = true;
    emailIds ;
    updateEmailCommunication(event){
        this.sendByEmail = event.target.checked;
        this.disableEmailInput = !event.target.checked;

        if(this.sendAllFlag){
            this.sendAllFlag = !event.target.checked;
        }
        if(this.sendClassified){
            this.sendClassified = !event.target.checked;
        }
        // Added By Moh Sarfaraj for BPE-167
        if(this.isAdminOwnerComm){
            this.isAdminOwnerComm = !event.target.checked;
        }
        this.isSendToSpecificEmirate = false;

        // Added by Moh Sarfaraj for BPE-113 start
        this.selectedAgentCategory = '';
        this.isAgentCategory = false;
        // Added by Moh Sarfaraj for BPE-113 end

        if(!this.sendByEmail){
            // updated by Moh Sarfaraj for BPE-113
            this.activeSections=['CommunicationType','MessageDetails','CommunicationPreference','AgencyDetails','AgentDetails', 'CommunicationByEmail', 'AgentCategory'];
        }else{
            this.selectedAgents=[];
            this.selectedAgencies=[];
        }
    }

    sendClassified = false;
    updateEmailToClassfiedBroker(event){
        this.sendClassified = event.target.checked;
        this.disableEmailInput = true;

        if(this.sendAllFlag){
            this.sendAllFlag = !event.target.checked;
        }
        if(this.sendByEmail){
            this.sendByEmail = !event.target.checked;
        }
        // Added By Moh Sarfaraj for BPE-167
        if(this.isAdminOwnerComm){
            this.isAdminOwnerComm = !event.target.checked
        }
        this.isSendToSpecificEmirate = false;

        // Added by Moh Sarfaraj for BPE-113 start
        this.selectedAgentCategory = '';
        this.isAgentCategory = false;
        // Added by Moh Sarfaraj for BPE-113 end

        if(!this.sendClassified){
            // updated by Moh Sarfarajf for BPE-113
            this.activeSections=['CommunicationType','MessageDetails','CommunicationPreference','AgencyDetails','AgentDetails', 'CommunicationByEmail', 'AgentCategory'];
        }else{
            this.selectedAgents=[];
            this.selectedAgencies=[];
        }
    }

    handleValidate(event){
        const emailRegex = /^([\w+-.%]+@[\w-.]+\.[A-Za-z]{2,4},?)+$/;
        let email = this.template.querySelector(".emailName");
        let emailVal = email.value;
        this.emailIds = event.target.value;

        if(!this.emailIds || this.emailIds === '' || this.emailIds === null || this.emailIds === undefined || emailVal.match(emailRegex)){
            email.setCustomValidity("");
        }else{
            email.setCustomValidity("Please enter valid email");
        }
        email.reportValidity();
    }

    classifiedBrokers(){
        this.isLoading = true;
        sendEmailBrokerFilterCommunication({
            commTemplateId          : this.recordId, 
            isClassifiedBroker      : true, 
            isCustomEmail           : false, 
            emails                  : this.emailIds, 
            isAgentCategory         : false,
            filter                  : '', 
            testEmail               : this.template.querySelector(".testEmail").value,
            bannerId                : this.selectedBannerId
        })
        .then(results=>{
            this.recordSuccess();
            this.isLoading = false;
        })
        .catch(error=>{
            this.isLoading = false;
            this.recordError();
        })
    }

    sendCommSpecificCustomEmails(){
        this.isLoading = true;
        sendEmailBrokerFilterCommunication({
            commTemplateId          : this.recordId, 
            isClassifiedBroker      : false, 
            isCustomEmail           : true, 
            emails                  : this.emailIds, 
            isAgentCategory         : false,
            filter                  : '', 
            testEmail               : this.template.querySelector(".testEmail").value,
            bannerId                : this.selectedBannerId
        })
        .then(results=>{
            this.recordSuccess();
            this.isLoading = false;
        })
        .catch(error=>{
            this.isLoading = false;
            this.recordError();
        })
    }
    // Added By Moh Sarfaraj for BPE-79 end

    // Added by Moh Sarfaraj for BPE-113 starts
    @track selectedAgentCategory;
    @track isAgentCategory = false;
    handleAgentCategory(event){
        this.isLoading = true;
        this.selectedAgentCategory = event.detail.value;
        
        this.isAgentCategory = true;
        this.selectedAgencies = [];
        this.selectedAgents = [];
        this.sendAllFlag = false;
        this.sendByEmail = false;
        this.sendClassified = false;
        this.isSendToSpecificEmirate = false;
        this.isLoading = false;
    }

    sendCommSelectedCategory(){
        sendEmailBrokerFilterCommunication({
            commTemplateId          : this.recordId, 
            isClassifiedBroker      : false, 
            isCustomEmail           : false, 
            emails                  : this.emailIds, 
            isAgentCategory         : true,
            filter                  : JSON.stringify(this.selectedAgentCategory), 
            testEmail               : this.template.querySelector(".testEmail").value,
            bannerId                : this.selectedBannerId
        })
        .then(results=>{
            this.recordSuccess();
            this.isLoading = false;
        })
        .catch(error=>{
            this.isLoading = false;
            this.recordError();
        })
    }
    // Added by Moh Sarfaraj for BPE-113 end

    // Added By Moh Sarfaraj for BPE-167 starts
    @track isAdminOwnerComm = false;
    handleAdminOwnerToggle(event){
        this.isLoading = true;
        this.isAdminOwnerComm = event.target.checked;
        this.disableEmailInput = true;
        this.selectedAgentCategory = '';
        this.isAgentCategory = false;
        this.selectedAgencies = [];
        this.selectedAgents = [];
        this.sendAllFlag = false;
        this.sendByEmail = false;
        this.sendClassified = false;
        this.isSendToSpecificEmirate = false;
        this.isLoading = false;
    }

    sendCommunicateToAdminAndOwners(){
        this.isLoading = true;
        sendEmailBrokerFilterCommunication({
            commTemplateId          : this.recordId, 
            isClassifiedBroker      : false, 
            isCustomEmail           : false, 
            emails                  : '', 
            isAgentCategory         : false,
            filter                  : 'sendToAgencyAdminOwner', 
            testEmail               : this.template.querySelector(".testEmail").value,
            bannerId                : this.selectedBannerId
        })
        .then(results=>{
            this.recordSuccess();
            this.isLoading = false;
        })
        .catch(error=>{
            this.isLoading = false;
            this.recordError();
        })
    }
    // Added By Moh Sarfaraj for BPE-167 end

    handleSectionToggle(event){
        this.activeSections = event.detail.openSections;
    }

    recordSuccess() {
        const evt = new ShowToastEvent({
            title: 'Success',
            message: 'Record saved successfully',
            variant: 'success',
        });
        this.dispatchEvent(evt);
        this.isLoading=false;
        this.handleNavigation();
    }

    recordError() {
        const evt = new ShowToastEvent({
            title: 'Failed',
            message: 'Record is not saved',
            variant: 'error',
        });
        this.dispatchEvent(evt);
        this.isLoading = false;
        this.handleNavigation();
    }
}