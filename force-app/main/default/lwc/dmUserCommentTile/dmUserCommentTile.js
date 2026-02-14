import { LightningElement, api } from 'lwc';

export default class DmUserCommentTile extends LightningElement {
    @api userComment;  

    get createdDate() {
        return new Date(this.userComment.CreatedDate);
    }

    get bodyLines() {
        if (this.userComment && this.userComment.Body) {
            const lines = this.userComment.Body.split('\n');  
            const withoutPTags = lines.map((line, index) => {
                const cleanedLine = line.replace(/<p[^>]*>|<\/p>/g, '\n');
                const isLink = cleanedLine.trim().startsWith('@');
                return { text: cleanedLine, key: index, isLink };
            });
            return withoutPTags;
        } else { 
            // return [];
            return [{ text: "Case created", key: 0, isLink: false }];
        }
    }

    handleClick(event) {
        event.preventDefault();
        const selectEvent = new CustomEvent('select', {
            detail: this.userComment.Id
        });
        this.dispatchEvent(selectEvent);
    }
}