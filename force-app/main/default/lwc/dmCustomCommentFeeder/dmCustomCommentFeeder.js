import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import BODY_FIELD from '@salesforce/schema/FeedItem.Body';
import PARENTID_FIELD from '@salesforce/schema/FeedItem.ParentId';
import STATUS_FIELD from '@salesforce/schema/Case.Status';
import createFeedItemRec from '@salesforce/apex/DMCustomCommentFeederController.createFeedItemRec';
import getFeedItemList from '@salesforce/apex/DMCustomCommentFeederController.getFeedItemList';
import getAldarUsers from '@salesforce/apex/DMCustomCommentFeederController.getAldarUsers';
import createFeedForAldar from '@salesforce/apex/DMCustomCommentFeederController.createFeedForAldar';
import getPMCPortalUsers from '@salesforce/apex/DM_PmcPortalCtrl.getPMCPortalUsers';
import CREATED_BY_FIELD from '@salesforce/schema/Case.CreatedById';
import CREATED_BY_NAME_FIELD from '@salesforce/schema/Case.CreatedBy.Name';
import OWNER_ID from '@salesforce/schema/Case.OwnerId';

export default class DmCustomCommentFeeder extends NavigationMixin(LightningElement) {

    @api recordId;
    @track commentBody;
    @track customerComment;
    @track userIdVal;
    @track ownerOptions = [];
    @track aldarUsers=[];
    comments;
    @api refreshChild;
    isDisable = false;
    isDisablePost = false;
    @api userInfo;

    //added by Aswathi
    @api showRequestorCmt;
    requestorId;

    get showRequestorDetails() {
        return this.showRequestorCmt === 'true';
    }

    get filteredComments() {
        if (!this.comments || !this.userInfo) {
            return [];
        }

        const userId = this.userInfo[0]?.Id;
        const userName = this.userInfo[0]?.Name;

        return this.comments.data.filter(comment => {
            const commentBody = comment.Body || '';
            const createdById = comment.CreatedBy?.Id || '';

            // Check if the body mentions the user or if the user is the creator
            return commentBody.includes(`@${userName}`) || createdById === userId;
        });
    }
    //End

    @wire(getRecord, { recordId: '$recordId', fields: [STATUS_FIELD,CREATED_BY_FIELD,CREATED_BY_NAME_FIELD,OWNER_ID] })
    caseRecord;

    get caseStatus() {
        return getFieldValue(this.caseRecord.data, STATUS_FIELD);
    }
    get caseCreatedById() {
        return getFieldValue(this.caseRecord.data, CREATED_BY_FIELD);
    }
    get caseCreatedByName() {
        return getFieldValue(this.caseRecord.data, CREATED_BY_NAME_FIELD);
    }
    get caseOwnerId() {
        return getFieldValue(this.caseRecord.data, OWNER_ID);
    }

    handleUserChange(event) {
        this.userIdVal = event.target.value;
    }

    @wire(getFeedItemList, { parentId: '$recordId' })
    comments; 

    connectedCallback() {
        this.getPMCPortalUsers();
        this.getAldarUsersInfo();
    }
    renderedCallback() {
        refreshApex(this.comments);
    }

    getAldarUsersInfo() {
        getAldarUsers()
            .then(data => {
                if (data) {
                    this.aldarUsers = data.map(user => ({
                        label: user.Name,
                        value: user.Id
                    }));
                }
            })
            .catch(error => {
                console.error('Error fetching PMC portal users:', error);
            });
    }

    getPMCPortalUsers() {
        getPMCPortalUsers()
            .then(data => {
                if (data) {
                    this.ownerOptions = data.map(user => ({
                        label: user.Name,
                        value: user.Id
                    }));
                }
            })
            .catch(error => {
                console.error('Error fetching PMC portal users:', error);
            });
    }

    recFeedItem = {
        Body: this.commentBody,
        ParentId: this.recordId,
        IsRichText: true
    };

    handleChange(event) {
        this.recFeedItem.Body = event.target.value;
    }

    handleSelect(event) {
        const userCommentId = event.detail;
        let userId = this.comments.data.find(
            (comment) => comment.Id === userCommentId
        ).CreatedBy.Id;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: userId,
                objectApiName: 'User',
                actionName: 'view'
            }
        });
    }

    handleAldarUserPost(event){
        
        const isInputsCorrect = [...this.template.querySelectorAll('lightning-combobox[data-name="aldar"],lightning-textarea[data-name="aldar"]')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);

        if (isInputsCorrect) { 
            this.isDisable = true; 
            this.recFeedItem.ParentId = this.recordId;
            createFeedForAldar({ 'feedItemRec': this.recFeedItem, userId: this.userIdVal })
                .then((response) => {
                    this.commentBody = '';
                    const textarea = this.template.querySelector('lightning-textarea[data-name="aldar"]');
                    if (textarea) {
                        textarea.value = '';
                    }
                    this.isDisable = false; 
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Comment Posted!',
                            variant: 'success'
                        })
                    );
                    refreshApex(this.comments);
                })
                .catch((error) => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error!',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                });
            
        }
    }

    handlePostClick(event) {
        const isInputsCorrect = [...this.template.querySelectorAll('lightning-combobox,lightning-textarea[data-name="internal"]')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);

        if (isInputsCorrect) { 
            this.isDisable = true; 
            this.recFeedItem.ParentId = this.recordId;
           
            createFeedItemRec({ 'feedItemRec': this.recFeedItem, userId: this.userIdVal, requestorId: null })
                .then((response) => {
                    this.commentBody = '';
                    const textarea = this.template.querySelector('lightning-textarea[data-name="internal"]');
                    if (textarea) {
                        textarea.value = '';
                    }
                    this.isDisable = false; 
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Comment Posted!',
                            variant: 'success'
                        })
                    );
                    refreshApex(this.comments);
                })
                .catch((error) => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error!',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                });
        }
    }

    customerFeedItem = {
        Body: this.customerComment,
        ParentId: this.recordId,
        IsRichText: true
    };

    handleCmtChange(event) {
        this.customerFeedItem.Body = event.target.value;
    
        if (event.target.name == 'customer'){
            this.requestorId = this.caseCreatedById;
        }else if(event.target.name == 'requestor'){
            this.requestorId = this.caseOwnerId;
        }
    }
    handleCustomerPost(){
           const isCommentsCorrect = [...this.template.querySelectorAll('lightning-textarea[data-name="customer"], lightning-textarea[data-name="requestor"]')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);

        if (isCommentsCorrect) { 
            this.isDisablePost = true;
            // console.log('CreatedById', this.caseCreatedById);
            // console.log('CreatedByName', this.caseCreatedByName);
            // console.log('requestorId',this.requestorId);
            this.customerFeedItem.ParentId = this.recordId;
           //console.log('Value--> ' + JSON.stringify(this.customerFeedItem));
            createFeedItemRec({ 'feedItemRec': this.customerFeedItem, userId: null, requestorId: this.requestorId })
                .then((response) => {
                    this.customerComment = '';
                    const textarea = this.template.querySelector('lightning-textarea[data-name="customer"]');
                    if (textarea) {
                        textarea.value = '';
                    }
                    this.isDisablePost = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Comment Posted!',
                            variant: 'success'
                        })
                    );
                    refreshApex(this.comments);
                })
                .catch((error) => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error!',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                });
        }
    }
}