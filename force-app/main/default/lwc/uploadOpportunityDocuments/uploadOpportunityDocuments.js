import { LightningElement, api, track, wire } from 'lwc';
import getCaseDocuments from '@salesforce/apex/ECSS_uploadOpportunityDocuments.getOpportunityDocuments';
import getDocumentVersion from '@salesforce/apex/ECSS_uploadOpportunityDocuments.getRelatedVersionOpportunityDocuments';
import getRelatedFilesByRecordId from '@salesforce/apex/ECSS_uploadOpportunityDocuments.getRelatedFilesByRecordId'
import saveFile from '@salesforce/apex/ECSS_uploadOpportunityDocuments.saveFile';
import updateStatus from '@salesforce/apex/ECSS_uploadOpportunityDocuments.updateStatus';
import checkAndMarkUsed from '@salesforce/apex/ECSS_uploadOpportunityDocuments.checkAndMarkUsed';
//import markExpired from '@salesforce/apex/ECSS_uploadOpportunityDocuments.markExpired';
import LOGO_IMAGE from '@salesforce/resourceUrl/ECSS_logo';
import FILE_IMAGE from '@salesforce/resourceUrl/fileIcon';
import INFO_IMAGE from '@salesforce/resourceUrl/infoIcon';
import ATTACH_IMAGE from '@salesforce/resourceUrl/attachedIcon';
import ADDDOC_IMAGE from '@salesforce/resourceUrl/addDocIcon';
import UploadBG from '@salesforce/resourceUrl/UploadBG';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ECSSUploadDocuments extends NavigationMixin(LightningElement) {

    @api availableActions = [];
    @api navigateFlow;
    @api screenHelpText;

    @api ids;
    @api recordId;
    @api Encrypted;
    @api QueryStringinp;
    docIds;
    @track data = [];
    @track fileNames = '';
    @track filesUploaded = [];
    @track FileLength = 0;
    @track ShowUpload = true;
    @track IsMessage = false;
    @track IsFileUploaded = false;
    @track Spinner = false;
    @track MessageInfo = '';
    @track docId;
    @track dataIsNotAvailable;
    @track showData = false;
    @track fileId;
    logoUrl = LOGO_IMAGE;
    fileUrl = FILE_IMAGE;
    infoUrl = INFO_IMAGE;
    attachUrl = ATTACH_IMAGE;
    addDocUrl = ADDDOC_IMAGE;
    bgUrl = UploadBG;
    pageName;
    temprecId;
    @track linkValid = true;
    @track loading = true;
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            // pageName comes from the URL after lightning/n/
            this.pageName = currentPageReference.attributes.apiName;

            this.temprecId = currentPageReference.state?.c__recordId;;

        }
    }

    connectedCallback() {
        console.log('###Connected Callback ', this.recordId);
        console.log('###Connected Callback1 ', this.ids);
        if (this.pageName === "Upload_Expired_Document") {
            this.recordId = this.temprecId;

        }
        else {

            this.recordId = this.ids;
            console.log('rec', this.recordId);
            /* validate link only if recordIs is Opportunity */
            if (this.recordId && this.recordId.startsWith('006')) {
                this.validateLink();

                /*checkAndMarkUsed({ recordId: this.recordId })
                   .then(used => {
                    console.log('Used:',used);
                        this.linkValid = used;
                    })
                    .catch(error => {
                        console.log('Error',error);
                       
                    });*/
            }

        }

        this.Spinner = false;
        this.getCaseDetails();
        // if(this.dataIsNotAvailable){
        //     this.closeBrowserWindow();
        // }
        console.log('connected call back called');
    }

    closeBrowserWindow() {
        try {
            // --- The Browser Close Workaround ---

            // 1. "Re-open" the current page using JavaScript and the '_self' target.
            // This is the critical step that tricks the browser into believing
            // the script initiated the window, making it eligible for closing.
            const opener = window.open(window.location.href, '_self');

            // 2. Immediately close the window.
            // This command must be in the same synchronous block as window.open()
            // to have the best chance of working.
            if (opener) {
                opener.close();
            } else {
                window.close();
            }

            // --- Fallback (if close fails due to lingering security) ---
            // If the tab remains open, redirect to a simple page in the portal
            // to stop the flow from restarting or showing the "Flow Finished" message.
            // window.location.href = '/s/'; // Redirect to Experience Cloud Home

        } catch (e) {
            console.error('Error during close attempt: ', e);
            // Fallback redirect in case of error
            window.location.href = '/s/';
        }
    }


    validateLink() {
        checkAndMarkUsed({ recordId: this.recordId, Encrypted: this.Encrypted })
            .then(result => {
                this.linkValid = result.isValid;
                console.log('VALID', this.linkValid);
                /*var expiryTime = result.expiryTime;
                console.log('time',expiryTime)
                if (this.linkValid) {
                    const delay = new Date(expiryTime).getTime() - Date.now();
                    if (delay > 0) {
                        setTimeout(() => this.expireNow(), delay);
                    }
                } else {
                    this.linkValid = false;
                }*/
            })
            .catch(error => {
                console.error('Error validating link', error);

            });
    }

    /* expireNow() {
         markExpired({ recordId: this.recordId })
             .then(() => {
                 this.linkValid = false;
                 
             })
             .catch(error => {
                 console.error('Error marking expired', error);
                 
             });
     }*/
    renderedCallback() {
        console.log('rendercallback called');
    }
    get acceptedFormats() {
        return ['.pdf', '.png'];
    }
    /*
        getCaseDetails() {
            console.log('this.recordId: ', this.recordId);
            getCaseDocuments({ oppID: this.recordId, QueryStringinp: this.QueryStringinp })
                .then(result => {
                    console.log('result: ', result);
    
                    this.data = JSON.parse(result);
                    if (this.data.length > 0) {
                        this.dataIsNotAvailable = false;
                    } else {
                        this.dataIsNotAvailable = true;
                        this.IsMessage = true;
                        this.MessageInfo = 'All Documents Are Submitted';
                    }
                    this.showData = true;
                })
                .catch(error => {
                    console.error('error: ', error);
                    this.ShowUpload = false;
                    this.error = error;
                    this.IsMessage = true;
                    this.MessageInfo = 'Error loading documents.';
                    this.dataIsNotAvailable = true;
                    this.showData = true;
                });
        }
    
    
        saveFiles(event) {
            const self = this;
            this.Spinner = true;
    
            this.docId = event.target.dataset.id;
            const parentID = event.target.dataset.id;
            const fileList = event.detail.files || event.target.files;
    
            [...fileList].forEach(file => {
                const fileReader = new FileReader();
    
                fileReader.onload = function () {
                    let fileContents = fileReader.result;
                    const base64Mark = 'base64,';
                    const dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;
                    fileContents = fileContents.substring(dataStart);
    
                    saveFile({
                        parentId: parentID,
                        fileName: file.name,
                        base64Data: encodeURIComponent(fileContents)
                    })
                        .then(result => {
                            console.log('Upload result:', result);
                            if (result === true || result === 'true') {
                                const updatedData = JSON.parse(JSON.stringify(self.data));
                                console.log(JSON.stringify(updatedData));
                                updatedData.forEach(doc => {
                                    if (doc.Id === parentID) {
                                        doc.Status__c = 'Submitted';
                                        doc.fileName = file.name;
                                    }
                                });
                                self.data = updatedData;
                                self.IsFileUploaded = true;
                            }
    
                            self.IsMessage = true;
                        })
                        .catch(error => {
                            console.error('Upload error:', error.message);
                            const evt = new ShowToastEvent({
                                title: 'Upload Error',
                                message: 'Failed to upload file. Please try again.',
                                variant: 'error'
                            });
                            self.dispatchEvent(evt);
                        })
                        .finally(() => {
                            self.Spinner = false;
                        });
                };
    
                fileReader.readAsDataURL(file);
            });
        }
    */


    getCaseDetails() {
        console.log('this.recordId: ', this.QueryStringinp);
        getDocumentVersion({ oppID: this.recordId, QueryStringinp: this.QueryStringinp })
            .then(result => {
                this.data = result;
                console.log('DATA', this.data);
                if (this.data.length > 0) {
                    this.dataIsNotAvailable = false;
                } else {
                    this.dataIsNotAvailable = true;
                    this.IsMessage = true;
                    this.MessageInfo = 'All Documents Are Submitted';
                }
                console.log('Fetched data:', JSON.stringify(result, null, 2));
                this.showData = true;
            })
            .catch(error => {
                console.error('error: ', error);
                this.ShowUpload = false;
                this.error = error;
                this.IsMessage = true;
                this.MessageInfo = 'Error loading documents.';
                this.dataIsNotAvailable = true;
                this.showData = true;
            });
    }
    handleDateChange(event) {
        const docId = event.target.dataset.id;
        const value = event.target.value;
        this.data = this.data.map(rec =>
            rec.Id === docId ? { ...rec, ExpiryDate: value } : rec
        );
    }
    handleUploadFinished(event) {
        var recordId = event.currentTarget.dataset.id;
        const uploadedFiles = event.detail.files;
        var url = '';
        console.log('ldjhujhduohdujndonjodndj', uploadedFiles);
        console.log('DOCID', recordId);
        console.log('record before updateStatus:', JSON.stringify(this.data));
        const record = this.data.find(rec => rec.Id === recordId);

        if (!record) {
            console.error('No record found with Id:', recordId);
            return;
        }

        updateStatus({
            documentId: recordId,
            expiryDate: record.ExpiryDate,
            Encrypted: this.Encrypted
        })
            .then(result => {
                console.log('Upload result:', result);
                if (result != '') {
                    url = result;
                }

                // Create new Files array from uploaded files
                const newFiles = uploadedFiles.map(file => ({
                    Title: file.name,
                    Version: file.contentVersionId,
                    contentdocID: file.documentId // Salesforce returns documentId for uploaded files
                }));
                let newStatus;
                const enc = (this.Encrypted ?? '').toString().trim().toLowerCase();
                if (enc === 'yes') newStatus = 'Submitted';
                else newStatus = 'Verified';


                // Find and update the matching document
                this.data = this.data.map(doc => {
                    if (doc.Id === recordId) {
                        return {
                            ...doc,
                            PreviewUrl: url,
                            Status__c: newStatus, // Update status if needed
                            Files: newFiles
                            //                    Files: [...doc.Files, ...newFiles] // Merge existing files with new ones
                        };
                    }
                    return doc;
                });

                console.log(this.data);
                console.log('data');
                console.log(JSON.stringify(this.data));




            })
            .catch(error => {
                console.error('Upload error:', error.message);
            });


    }


    getBaseUrl() {
        return 'https://' + location.host + '/';
    }

    previewHandler(event) {

        const versionId = event.target.dataset.version;

        if (!versionId) {
            console.error('No versionId provided for preview.');
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                recordIds: versionId,
                selectedRecordId: versionId,
            }
        }, false);

        //     var previewUrl = event.target.dataset.url;
        // console.log(previewUrl);
        // this[NavigationMixin.Navigate]({
        //     type: 'standard__webPage',
        //     attributes: {
        //         url: previewUrl
        //     }
        // },false);
    }



    previewHandlerr(event) {
        var previewUrl = event.target.dataset.url;
        console.log(previewUrl);
        //   window.location.href = previewUrl;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: previewUrl
            }
        }, false);
    }


    handleClickBox(event) {
        this.template.querySelector('lightning-file-upload').click();
    }


}