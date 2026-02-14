public with sharing class JWTToken {

    public static String issueToken(APISetting__mdt apiSetting, Boolean isSandbox, String pvtKey) {

        JWTModel jwtModel = new JWTModel(apiSetting, IsSandbox);

        JSONGenerator header = JSON.createGenerator(false);
        header.writeStartObject();
        header.writeStringField('alg', 'RS256');
        header.writeStringField('typ', 'JWT');
        header.writeEndObject();
        String encodedHeader = base64URLencode(Blob.valueOf(header.getAsString()));

        JSONGenerator body = JSON.createGenerator(false);
        body.writeStartObject();
        body.writeStringField('iss', jwtModel.iss);
        body.writeStringField('sub', jwtModel.sub);
        body.writeStringField('aud', jwtModel.aud);
        Long rightNow = (dateTime.now().getTime() / 1000) + 1;
        body.writeNumberField('iat', rightNow);
        body.writeNumberField('exp', (rightNow + 10000));
        body.writeStringField('scope', jwtModel.scope);
        body.writeEndObject();
        String encodedBody = base64URLencode(Blob.valueOf(body.getAsString()));

        String jwt = encodedHeader + '.' + encodedBody;

        Blob privateKey = EncodingUtil.base64Decode(pvtKey);
        Blob signature = Crypto.sign('rsa-sha256', Blob.valueOf(jwt), privateKey);

        jwt = jwt + '.' + base64URLencode(signature);

        return jwt;
    }

    public static String base64URLencode(Blob input){ 
        String output = encodingUtil.base64Encode(input);
        output = output.replace('+', '-');
        output = output.replace('/', '_');
        while (output.endsWith('=')) {
            output = output.subString(0, output.length() - 1);
        }
        return output;
    }

    public class JWTModel {
        public String iss               {get;set;}
        public String sub               {get;set;}
        public String aud               {get;set;}
        public String scope             {get;set;}

        public JWTModel(APISetting__mdt apiSetting, Boolean isSandbox) {
            this.iss = apiSetting.APIKey__c;
            this.sub = apiSetting.APIId__c;
            this.scope = apiSetting.Source__c;

            KeyValueModel keyValueModel = (KeyValueModel)JSON.deserializeStrict(apiSetting.Headers__c, KeyValueModel.class);
            this.aud = isSandbox ? keyValueModel.sandbox : keyValueModel.production;
        }
    }

    public class KeyValueModel {
        public String sandbox;
        public String production;
    }
}