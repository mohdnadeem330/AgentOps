import { LightningElement, api, track, wire } from 'lwc';
import customerDocuments from '@salesforce/apex/dmCaseDocumentsHandler.getCustomerDocuments';
import { NavigationMixin } from 'lightning/navigation';
import createDoc from '@salesforce/apex/dmCaseDocumentsHandler.createDocument';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { deleteRecord } from 'lightning/uiRecordApi';
import ExternalStyleNew from '@salesforce/resourceUrl/ExternalStyleNew';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import { reduceErrors } from 'c/ldsUtils';
import getSASUrl from '@salesforce/apex/CalloutToBlobstorage.getSASUrl';
import getBulkSASUrls from '@salesforce/apex/CalloutToBlobstorage.getBulkSASUrls';
import jszipLib from '@salesforce/resourceUrl/DMJSZip';

export default class DmCaseCustomerDocuments extends NavigationMixin(LightningElement) {
    @api recordId;
    showDocRecModal = false;
    sObjectLookupApiname = 'Case__c';
    @track docRecords = [];
    noDocuments = false;
    @track recordTypeId;
    showOtherName = false;
    docObj = new Object();
    showSpinner = false;
    btnDisable = false;
    filetype = 'LFU';
    get acceptedFormats() {
        return ['.pdf', '.png'];
    }
    get documentOptions() {
        return [
            { label: 'CAS', value: 'CAS' },
            { label: 'Customer TLA', value: 'Customer TLA' },
            { label: 'Draft TLA', value: 'Draft TLA' },
            { label: 'Invoice', value: 'Invoice' },
            { label: 'Plot Allocation Plan', value: 'Plot Allocation Plan' },
            { label: 'Temporary License Agreement', value: 'Temporary License Agreement' },

        ];
    }

    connectedCallback() {
        this.docObj.SObjectType = 'Document__c';
        this.docObj.Case__c = this.recordId;
        this.fetchCustomerDocument();
        Promise.all([
            loadStyle(this, ExternalStyleNew),
            loadScript(this, jszipLib)
        ])
            .then(() => {
            })
            .catch(error => {
            });
    }
    fetchCustomerDocument() {
        customerDocuments({ caseId: this.recordId })
            .then(result => {
                if (result) {
                    /* result.forEach(item => {
                        item.isCheck = false;
                        if (Object.keys(item.contentVersion).length == 0)
                            item.availableDoc = false;
                        else
                            item.availableDoc = true;
                    }); */

                    result.forEach(item => {
                        item.isCheck = false;
                        if (item.externalFiles.length > 0) {
                            item.externalFileUrl = item.externalFiles[0].External_URL__c;
                            item.externalFileName = item.externalFiles[0].File_Name__c;
                            item.availableExternalFile = true;
                            item.availableDoc = false;
                        } else if (Object.keys(item.contentVersion).length > 0) {
                            item.availableDoc = true;
                            item.availableExternalFile = false;
                        }

                    });
                    this.docRecords = result;
                } else {
                    this.noDocuments = true;
                }

            }).catch(error => {
                //console.log(JSON.stringify(error));
            });
    }
    handleChange(event) {
        if (event.target.name == 'DocumentType__c') {
            if (event.target.value == 'Others') {
                this.showOtherName = true;
            } else {
                this.showOtherName = false;
                this.docObj.Other_Document_Name__c = '';
            }
        }
        this.docObj[event.target.name] = event.target.value;
    }
    createDocument() {
        this.showSpinner = true;
        this.btnDisable = true;
        createDoc({ doc: this.docObj, recTypeDevName: 'CustomerDocument' })
            .then(data => {
                this.showDocRecModal = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'success',
                        message: 'Document has been created successfully.',
                        variant: 'success'
                    })
                );
                this.fetchCustomerDocument();
                this.showSpinner = false;
                this.btnDisable = false;
            })
            .catch(error => {
                this.showSpinner = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'error',
                        message: 'Unable to create document, please check with admin',
                        variant: 'error'
                    })
                );
                this.btnDisable = false;
                //console.log('error', JSON.stringify(error));
            });
    }
    handleUploadFinished(event) {
        this.fetchCustomerDocument();
    }

    showCreateDoc(event) {
        this.showDocRecModal = true;
    }
    closeDocRecModal() {
        this.showDocRecModal = false;
    }
    filePreview(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: event.target.dataset.id
            }
        })
    }
    /*  updateDocumentHanlder(event) {
         let docObj = new Object();
         docObj.SObjectType = 'Document__c';
         docObj.Id = event.target.dataset.id;
         docObj.AvailableForExternalUsers__c = event.target.checked;
         updateDocument({ doc: docObj })
             .then(data => {
                 
             })
             .catch(error => {
                 console.log('Error -', JSON.stringify(error));
             });
     } */
    async deleteDocumentHandler(event) {

        try {
            await deleteRecord(event.target.dataset.id);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Document has been deleted successfully.',
                    variant: 'success'
                })
            );
            this.fetchAldardocument();

        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error deleting record',
                    message: reduceErrors(error).join(', '),
                    variant: 'error'
                })
            );
        }
    }  /*  
        deleteDocument({recId : event.target.dataset.id})
            .then(data => {
               this.fetchCustomerDocument();
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'success',
                        message: 'Document has been deleted successfully.',
                        variant: 'success'
                    })
                );
            }).catch(error => {
                 console.log('Error -', JSON.stringify(error));
            }); */

    downloadDocument(event) {
        const docId = event.target.dataset.id;
        let fileName = event.target.dataset.name;
        let ext = event.target.dataset.ext;
        const url = "/sfc/servlet.shepherd/document/download/" + docId;
        const downloadLink = document.createElement('a');
        downloadLink.href = url;
        downloadLink.setAttribute('download', '');
        downloadLink.download = fileName + '.' + ext;
        downloadLink.click();

    }
    handleCheck(event) {
        let index = event.target.dataset.index;
        this.docRecords[index].isCheck = event.target.checked;

    }
    async downloadAllDocs() {
        try {
            let externalFiles = [];

            // Collect selected external files
            this.docRecords.forEach(item => {
                if (item.isCheck && item.availableExternalFile) {
                    externalFiles.push({
                        url: item.externalFileUrl,
                        fileName: item.externalFileName
                    });
                }
            });

            // If no files selected, show warning
            if (externalFiles.length === 0) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Warning',
                        message: 'Please choose at least one external document to download.',
                        variant: 'warning'
                    })
                );
                return;
            }

            this.showSpinner = true;
            const zip = new JSZip();

            // Get signed URLs from Apex
            const urls = externalFiles.map(f => f.url);
            const sasResults = await getBulkSASUrls({ urls });

            // Fetch each file and add to zip
            const filePromises = sasResults.map((res, i) => {
                if (res.signedUrl) {
                    return fetch(res.signedUrl)
                        .then(r => r.blob())
                        .then(blob => {
                            zip.file(externalFiles[i].fileName, blob);
                        });
                }
            });

            // Wait for all fetches to complete
            await Promise.all(filePromises);

            // Generate zip and download
            const content = await zip.generateAsync({ type: 'blob' });
            const downloadLink = document.createElement('a');
            downloadLink.href = URL.createObjectURL(content);
            downloadLink.download = 'Customer_Documents.zip';
            document.body.appendChild(downloadLink);
            downloadLink.click();
            document.body.removeChild(downloadLink);
            URL.revokeObjectURL(downloadLink.href);
            this.showSpinner = false;

        } catch (error) {
            console.error('Error downloading external files:', error);
            this.showSpinner = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Something went wrong while downloading external files.',
                    variant: 'error'
                })
            );
        }
    }
    downloadExtFile(event) {
        this.showSpinner = true;
        const url = event.target.dataset.url;
        const fileName = event.target.dataset.filename;
        getSASUrl({ url: url, type: this.filetype }).then(res => {
            this.showSpinner = false;
            /*  const link = document.createElement('a');
             link.href = res;
             link.download = fileName || ''; 
             link.target = '_blank';
             document.body.appendChild(link);
             link.click(); 
             document.body.removeChild(link);  */
            fetch(res)
                .then(response => response.blob())
                .then(blob => {
                    const blobUrl = window.URL.createObjectURL(blob);
                    const downloadLink = document.createElement('a');
                    downloadLink.href = blobUrl;
                    downloadLink.setAttribute('download', fileName);
                    document.body.appendChild(downloadLink);
                    downloadLink.click();
                    document.body.removeChild(downloadLink);
                    window.URL.revokeObjectURL(blobUrl); // Clean up the URL object
                })
                .catch(error => console.error('Error downloading file:', error));

        }).catch(err => {
            //console.log('err', err);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'error',
                    message: 'Unable to download this file',
                    variant: 'error'
                })
            );
        });

    }
    previewExtFile(event) {
        this.showSpinner = true;
        const url = event.target.dataset.url;
        getSASUrl({ url: url, type: this.filetype }).then(res => {
            this.showSpinner = false;
            window.open(res, '_blank')
        }).catch(err => {
            //console.log('err', err);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'error',
                    message: 'Unable to preview this file',
                    variant: 'error'
                })
            );
        });
    }
}