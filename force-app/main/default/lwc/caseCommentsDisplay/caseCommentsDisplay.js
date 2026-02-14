import { LightningElement, api, track } from 'lwc';
import getCaseCommentsAndPosts from '@salesforce/apex/North_baniyasRequest.getCaseCommentsAndPosts';

export default class CaseCommentsDisplay extends LightningElement {
    @api parentId; // CaseId from parent

    @track comments = [];
    @track displayedComments = [];
    @track showModal = false;
    @track hasMore = false;

    connectedCallback() {
        console.log('Child Called');
        this.fetchComments();
    }

    @api
    refreshComments() {
        this.fetchComments();
    }

    fetchComments() {
    if (!this.parentId) {
        return;
    }

    getCaseCommentsAndPosts({ caseId: this.parentId })
        .then(result => {
            // Filter out comments with empty body
            const filtered = result.filter(item => item.CommentBody && item.CommentBody.trim() !== '');
            this.comments = [...filtered];
            console.log('Comments Data-->',JSON.stringify(this.comments));
            this.displayedComments = [...this.comments.slice(0, 5)];
            this.hasMore = this.comments.length > 5;
        })
        .catch(error => {
            console.error('Error fetching comments & posts:', error?.message || error);
        });
    }


    handleMoreClick() {
        this.showModal = true;
    }

    closeModal() {
        this.showModal = false;
    }
}