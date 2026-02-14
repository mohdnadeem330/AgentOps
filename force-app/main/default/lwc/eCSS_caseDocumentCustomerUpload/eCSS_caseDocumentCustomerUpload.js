import { LightningElement, api, wire,   track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import uploadDocuments from '@salesforce/apex/ECSS_caseDocumentCustomerUpload.uploadDocuments'
import getCustomerDocuments from '@salesforce/apex/ECSS_caseDocumentCustomerUpload.getCustomerDocuments';

export default class FileUploaderCompLwc extends LightningElement {
    @api recordId;
    //@api ecssUnitId;
    //@api accountId;
    fileData
    @track isLoading = true;
    documentsList =[];
    @track filesToUpload = [];
    requiredDocIds =[];
    documentWrapperList =[];
    startFlag= false;
   

    @wire(CurrentPageReference)
    getCurrentPageReference(currentPageReference) {
        if(currentPageReference && currentPageReference.state.c__recordId =='' || currentPageReference && currentPageReference.state.c__recordId == null){
            this.isLoading =false;
        }
        else{
            if(!this.startFlag)
            {
                this.startFlag= true
                if (currentPageReference && currentPageReference.state.c__recordId) {
                    this.recordId = currentPageReference.state.c__recordId;
                    console.log('Record ID from URL:', this.recordId);   
                    this.getCustomerDocs();
                } 
                /*if (currentPageReference && currentPageReference.state.c__ecssUnitId) {
                    this.ecssUnitId = currentPageReference.state.c__ecssUnitId;
                    console.log('ECSS Unit ID from URL:', this.ecssUnitId);   
                } 
                if (currentPageReference && currentPageReference.state.c__accountId) {
                    this.accountId = currentPageReference.state.c__accountId;
                    console.log('Account ID from URL:', this.accountId);   
                } */
            
             this.isLoading = false; // Set loading false once recordId is retrieved
            }
        }

    }
    
    getCustomerDocs()
    {
        this.documentsList=[];
        this.requiredDocIds = [];
        this.filesToUpload = [];
        
   // @wire(getCustomerDocuments,{ recordId:'$recordId'})
    getCustomerDocuments({recordId:this.recordId}) 
        .then(data=>
            {   
            this.documentsList = data;
            console.log('data',data);
            this.documentsList.forEach(doc=>{
                const documentId = doc.Id;
                const documentType = doc.DocumentType__c;
                const fileAttached = false;
                const fileName ='';
                this.documentWrapperList.push({documentId,documentType,fileAttached,fileName});
               
                this.requiredDocIds.push(doc.Id);
            });
             //console.log('D',this.documentWrapperList);
            
        })
        .catch(error =>{
                console.log(error);
        })
    
    }

    handleFileChange(event) {
        
        const docId = event.target.dataset.id;
        const file = event.target.files[0];
        
        if (file) {
            const fileName = file.name;
            const reader = new FileReader();
            
            reader.onloadend = () => {
                const base64Data = reader.result.split(',')[1];
                
                    if(!this.filesToUpload.find(item => item.docId === docId)) // if first time to add file to a document
                    {
                        //console.log('NOT FOUND');
                        this.filesToUpload.push({ docId, fileName, base64Data, file });
                    }
                    else
                    {
                         const item = this.filesToUpload.find(row => row.docId === docId);
                         item.fileName = fileName;
                         item.base64Data = base64Data;
                         item.file = file;
                        // console.log('CONST',item);
                    }

                if(this.documentWrapperList.find(item=>item.documentId===docId))
                {
                    //console.log('found');
                    this.documentWrapperList.find(item=>item.documentId===docId).fileName = fileName;
                    this.documentWrapperList.find(item=>item.documentId===docId).fileAttached = true;
                }
                    
             
                
            };
            
            reader.readAsDataURL(file);
        }
        console.log('FILES',this.filesToUpload);
    }

    handleSubmit() {
        this.isLoading = true;
        // Collect document details and send them to Apex for processing
        const documentFiles = this.filesToUpload.map(file => ({
            docId: file.docId,
            fileName: file.fileName,
            base64Data: file.base64Data,
        }));
        //console.log('DOC',documentFiles);
        uploadDocuments({ recordId: this.recordId, documents: documentFiles, requiredDocIds:this.requiredDocIds })
            .then(result => {
                // Handle success, e.g., show success message or navigate
                console.log('Documents uploaded successfully:', result);
                this.isLoading = false;
                let allUploaded = false;
                result.forEach(doc =>{
                    console.log('STatus',doc.Status__c);
                    if(doc.Status__c === 'Uploaded')
                    {   
                        allUploaded = true;
                    }
                })
                if(allUploaded){
                    this.showToast('Success','Documents Uploaded Successfully','success');
                    this.getCustomerDocs(); 
                }
            })
            .catch(error => {
                // Handle error
                console.error('Error uploading documents:', error);
                this.isLoading = false;
                this.showToast('Error','Error uploading documents:'+ error,'error');
            });
    }
   

    showToast(title,message,variant){
        this.isLoading = false;
        const toastEvent = new ShowToastEvent({
            title, 
            message: message,
            variant:variant
        })
        this.dispatchEvent(toastEvent)
    }
    
}