import { LightningElement,api,wire,track } from 'lwc';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import getAllAgency from '@salesforce/apex/CommunicationController.getAllAgency';
import getReletedCommunicationRecords from '@salesforce/apex/CommunicationController.getReletedCommunicationRecords';
import getRelatedUsers from '@salesforce/apex/CommunicationController.getRelatedUsers';
import updateUserSelection from '@salesforce/apex/CommunicationController.updateUserSelection';
import getExistingCDL from '@salesforce/apex/CommunicationController.getExistingCDL';
import reparentCDL from '@salesforce/apex/CommunicationController.reparentCDL';

import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; 
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';


export default class ComposeEmailModal extends LightningElement {

    @api recordId; 
    @api communicationTypeValue; 
    @api viewFlag =false;
    fireRefresh=false;
    activeSections=['CommunicationType','MessageDetails','AgencyDetails','AgentDetails'];
    isEmailCommincation=false;
    isLoading=true;
    isPublished=false;
    initLoad=true;
    modalheader = 'Compose Email';
    @track uploadedFiles=[];
    @track complaiance=false;
    agencyList;
    @track selectedAgencies=[];

    agentList
    @track selectedAgents=[];
    
    get hasRecordId() {
        return (this.recordId != '' && this.recordId !=null && this.recordId != undefined );
    }

    @wire(getAllAgency)
    getAllAgencyRecords({ error, data }) {
        if (data) {
            this.agencyList=[];
            for(let i=0; i<data.length ;i++){
                this.agencyList.push({ label: data[i].Name, value: data[i].Id });
            }
        } else if (error) {
            this.agencyList=[];
        }
    }

    handleTypeChange(event){
        this.isEmailCommincation= (event.target.value =='Email');
    }

    handleAgencyChange(event){
        this.selectedAgencies = event.detail.value;
        this.initAgentRecords();
    }
    handleComplaiceChange(event){
        this.complaiance = event.detail.checked;
        
    }
    initAgentRecords(){
        this.isLoading=true;
        getRelatedUsers({accountIds:  this.selectedAgencies })
            .then(data => {
                this.agentList=[];
                for(let i=0; i<data.length ;i++){
                    this.agentList.push({ label: data[i].Contact.Name, value: data[i].Id });
                    if(this.selectedAgents.findIndex((item) => item === data[i].Id) === -1){
                        this.selectedAgents.push(data[i].Id);
                    }
                }
                
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
    submitDetails(){
        this.isLoading=true;
        
        var isError =false;
        this.template.querySelectorAll('lightning-input-field').forEach(element => {
            element.reportValidity();
            if(element.required && !element.value && !element.disabled ){
                isError =true;
            }
        });
        
        //if no error then only call apex from handleSubmit
        if (isError) {
            this.isLoading=false;
        } else {
            this.template.querySelector('.submitCom').click();
        }
    }
    handleSuccess(event){
        this.recordId= event.detail.id;
        this.isLoading=true;
        if(this.uploadedFiles.length > 0){
            reparentCDL({fileData : this.uploadedFiles  ,templateId : this.recordId })
            .then(data => {
            })
            .catch(error => {
                console.error(error);
            });
        }
        if(this.selectedAgents.length >0 ){
            updateUserSelection({templateId : this.recordId , userIDs:  this.selectedAgents, sendAllFlag: false ,testEmail : ''  })
                .then(data => {

                    const evt = new ShowToastEvent({
                        title: 'Success',
                        message: 'Record saved successfully',
                        variant: 'success',
                    });
                    this.dispatchEvent(evt);
                    this.isLoading=false;
                    this.fireRefresh=true;
                    this.closeModal();
                    
                })
                .catch(error => {
                    console.error('error');
                    const evt = new ShowToastEvent({
                        title: 'Error',
                        message: 'Error while storing data '+error,
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                    this.isLoading=false;
                    
                });
        }else{
            const evt = new ShowToastEvent({
                title: 'Success',
                message: 'Record saved successfully',
                variant: 'success',
            });
            this.dispatchEvent(evt);
            this.isLoading=false;
            
        }
    }

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

    handleLoad(){
        console.log('handle Load loaded');
        this.isEmailCommincation = (this.communicationTypeValue =='Email');
            if(this.hasRecordId && this.initLoad){
                this.isPublished=true;
            getReletedCommunicationRecords({recordId : this.recordId })
            .then(data => {
                for(let i=0; i<data[0].Communication__r.length ;i++){
                    if(this.selectedAgencies.findIndex((item) => item === data[0].Communication__r[i].Agency__c) === -1){
                        this.selectedAgencies.push(data[0].Communication__r[i].Agency__c);
                    }
                    if(this.selectedAgents.findIndex((item) => item === data[0].Communication__r[i].Recipient__c) === -1){
                        this.selectedAgents.push(data[0].Communication__r[i].Recipient__c);
                    }
                }
                if(this.selectedAgencies.length > 0){
                    this.initAgentRecords();
                }
                this.isEmailCommincation = data[0].Type__c =='Email';
                /*if(this.viewFlag){
                    this.modalheader=data[0].Title__c;
                }*/
                this.isPublished = data[0].Status__c =='Published';
                if(this.isPublished){
                    this.modalheader=data[0].Title__c;
                }
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
                console.error(error)
                this.uploadedFiles = [];
            });
        }
        console.log('false Load loaded')
        this.initLoad=false;
        this.isLoading=false;
    }

  
    
    handleUploadFinished(event){
        for (let i = 0; i < event.detail.files.length; i++) {
            this.uploadedFiles.push({'name':event.detail.files[i].name , 'documentId':event.detail.files[i].documentId } )
        }
    }


    uploadeFileIcon = resourcesPath + "/ALDARResources/svg/UploadedFileIcon.svg";
    deleteFileIcon = resourcesPath + "/ALDARResources/svg/DeleteFileIcon.svg";

    @track uploadedFilesList;

    _selected = [];
    @track agencyPickListValues = [];
    @track agentPickListValues = [];
    @track agencyAccounts= [];

    /*typePickListValues = [
        {label: "None", value: null },
        {label: "Email", value: 'Email' },
        {label: "SMS", value: 'SMS' },
        {label: "WhatsApp", value: 'WhatsApp' },
    ];

    statusPickListValues = [
        {label: "None", value: null },
        {label: "Draft", value: 'Draft' },
        {label: "Published", value: 'Published' },
    ];*/

    /*get options() {
        return [
            { label: 'English', value: 'en' },
            { label: 'German', value: 'de' },
            { label: 'Spanish', value: 'es' },
            { label: 'French', value: 'fr' },
            { label: 'Italian', value: 'it' },
            { label: 'Japanese', value: 'ja' },
        ];
    }*/

    get selected() {
        return this._selected.length ? this._selected : 'none';
    }

    handleChange(event) {
        this[event.target.name] = event.target.value;
    }

    async getAllAgencyData(){
        let allAgencyData = [];
        allAgencyData = await getAllAgency();
        for (let i = 0; i < allAgencyData.length; i++)
        {
            this.agencyPickListValues.push({ label: allAgencyData[i].Name, value: allAgencyData[i].Id });
            this.agencyAccounts.push(allAgencyData[i].Id);
        }
        this.getAllAgentData();
    }

    async getAllAgentData(){
        let allAgentData = [];
        allAgentData = await getRelatedUsers({ accountIds : this.agencyAccounts });
        for (let i = 0; i < allAgentData.length; i++)
        {
            this.agentPickListValues.push({ label: allAgentData[i].Name, value: allAgentData[i].Id });
        }

    }
    
    connectedCallback(){
        this.getAllAgencyData();
    }

    async openfileUpload(event) {
    
        function getBase64(file) {
            return new Promise((resolve, reject) => {
                const reader = new FileReader();
                reader.readAsDataURL(file);
                reader.onload = () => resolve(reader.result);
                reader.onerror = error => reject(error);
            });
        }
    
        await Array.from(event.target.files).forEach(file => {
            var base64;
            getBase64(file).then(
                data => {
                    base64 = data.split(',')[1];
                }
            );
            
            var reader = new FileReader();
            
            
                reader.onload = () => {
                    this.uploadedFilesList.push({
                        'filename': file.name,
                        'base64': base64,
                    });
                }
                reader.readAsDataURL(file);
            
            });
        
        }
    
        async getBase64(file) {
            return await new Promise((resolve, reject) => {
                const reader = new FileReader();
                reader.readAsDataURL(file);
                reader.onload = () => {
                    resolve(reader.result);
                    return reader.result.split(',')[1];
                }
                reader.onerror = error => {
                    reject(error)
                    console.error('Error: ', error);
                    return '';
                };
            });
        }
    
    
        get acceptedFormats() {
            return ['.pdf', '.png', '.jpg', '.jpeg'];
        }
    
        closeModal(){
            this.dispatchEvent(new CustomEvent('close', {detail:{isOpen:false,fireRefresh:this.fireRefresh}}));
        }
    
        
    }