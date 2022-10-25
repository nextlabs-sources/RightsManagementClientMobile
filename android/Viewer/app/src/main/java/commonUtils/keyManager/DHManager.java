package commonUtils.keyManager;

import android.content.SharedPreferences;
import android.util.Base64;
import android.util.Log;

import java.io.ByteArrayInputStream;
import java.math.BigInteger;
import java.security.KeyFactory;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.KeyStore;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.SecureRandom;
import java.security.cert.CertPath;
import java.security.cert.Certificate;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;
import java.util.ArrayList;
import java.util.Collection;
import java.util.ConcurrentModificationException;
import java.util.Iterator;
import java.util.List;

import javax.crypto.KeyAgreement;
import javax.crypto.SecretKey;
import javax.crypto.interfaces.DHPublicKey;
import javax.crypto.spec.DHParameterSpec;

import appInstance.ViewerApp;

/**
 * Created by aning on 8/17/2016.
 */
public class DHManager {
    private static final String KEY_DH = "DH";
    private static final String KEY_DH_DES = "DES";
    private static String P = "D310125B294DBD856814DFD4BAB4DC767DF6A999C9EDFA8F8D7B12551F8D71EF6032357405C7F11EE147DB0332716FC8FD85ED027585268360D16BD761563D7D1659D4D73DAED617F3E4223F48BCEFA421860C3FC4393D27545677B22459E852F5254D3AC58C0D63DD79DE2D8D868CD940DECF5A274605DB0EEE762020C39D0F6486606580EAACCE16FB70FB7C759EA9AABAB4DCBF941891B0CE94EC4D3D5954217C6E84A9274F1AB86073BDF9DC851E563B90455B8397DAE3A1B998607BB7699CEA0805A7FF013EF44FDE7AF830F1FD051FFAEC539CE4452D8229098AE3EE2008AB9DB7B2C948312CBC0137C082D6672618E1BFE5D5006E810DC7AA7F1E6EE3";
    private static String G = "64ACEBA5F7BC803EF29731C9C6AE009B86FC5201F81BC2B8F84890FCF71CAD51C1429FD261A2A715C8946154E0E4E28EF6B2D493CC1739F5659E9F14DD14037F5FE72B3BA4D9BCB3B95B8417BDA48F118E61C8214CF8D558DA6774F08B58D97B2CCE20F5AA2F8E9539C014E7761E4E6336CFFC35127DDD527206766AE72045C11B0FF4DA76172523713B31C9F18ABABA92612BDE105141F04DB5DA3C39CDE5C6877B7F8CD96949FCC876E2C1224FB9188D714FDD6CB80682F8967833AD4B51354A8D58598E6B2DEF4571A597AD39BD3177D54B24CA518EDA996EEDBA8A31D5876EFED8AA44023CC9F13D86DCB4DDFCF389C7A1435082EF69703603638325954E";

    private static BigInteger p = new BigInteger(P, 16);
    private static BigInteger g = new BigInteger(G, 16);

    public static KeyPair generateDHKeyPair() {

        KeyPair keyPair = null;
        try {

            DHParameterSpec dhParameterSpec = new DHParameterSpec(p, g);
            KeyPairGenerator generator = KeyPairGenerator.getInstance(KEY_DH);
            generator.initialize(dhParameterSpec, new SecureRandom());
            keyPair = generator.generateKeyPair();
        } catch (Exception e) {
            e.printStackTrace();
        }
        return keyPair;
    }

    public static List<String> extractPubKey(String certificates) {
        List<String> publicKeys = null;
        try {
            CertificateFactory cf = CertificateFactory.getInstance("X.509");
            ByteArrayInputStream stream = new ByteArrayInputStream(certificates.getBytes());
            Collection collection = cf.generateCertificates(stream);

            publicKeys = new ArrayList<>();
            Iterator i = collection.iterator();
            while (i.hasNext()) {
                X509Certificate cert = (X509Certificate) i.next();
                PublicKey pubKey = cert.getPublicKey();
                String publicKey = Base64.encodeToString(pubKey.getEncoded(), Base64.DEFAULT);
                publicKeys.add(publicKey);
            }

        } catch (CertificateException ce) {
            ce.printStackTrace();
        }
        return publicKeys;
    }


    public static String getAgreementPublicKey(List<String> pubKeys) {
        // produce the secret key  by server public key, here we use the last public key if have multiple keys.
        String agreementPubKey = null;
        try {
            if (pubKeys.size() > 0) {

                String pubKey = pubKeys.get(pubKeys.size() - 1); // get the last one.
                // 1.init the server public key
                byte[] bytes = Base64.decode(pubKey, Base64.DEFAULT);
                X509EncodedKeySpec keySpec = new X509EncodedKeySpec(bytes);
                KeyFactory factory = KeyFactory.getInstance(KEY_DH);
                PublicKey publicKey = factory.generatePublic(keySpec);

                // 2. init client private key
                String privateKey = ViewerApp.getInstance().getSession().getPrivateKey();
                byte[] privateBytes = Base64.decode(privateKey, Base64.DEFAULT);
                PKCS8EncodedKeySpec spec = new PKCS8EncodedKeySpec(privateBytes);
                PrivateKey localPrivateKey = factory.generatePrivate(spec);

                // 3. Generates the shared secret.
                KeyAgreement agreement = KeyAgreement.getInstance(factory.getAlgorithm());
                agreement.init(localPrivateKey);
                agreement.doPhase(publicKey, true);

                byte[] sharedSecret = agreement.generateSecret();
                agreementPubKey = bytesToHexString(sharedSecret);

            }
        } catch (Exception e) {
            e.printStackTrace();
        }


        return agreementPubKey;
    }

    public static List<String> getAgreementsPublicKey(List<String> pubKeys) {
        // produce the secret key  by server public key, here we use the last public key if have multiple keys.

        List<String> listAgreements = new ArrayList<>();
        try {
            if (pubKeys.size() > 0) {

                String agreementPubKey = null;
                for (String pubKey : pubKeys) {
                    // 1.init the server public key
                    byte[] bytes = Base64.decode(pubKey, Base64.DEFAULT);
                    X509EncodedKeySpec keySpec = new X509EncodedKeySpec(bytes);
                    KeyFactory factory = KeyFactory.getInstance(KEY_DH);
                    PublicKey publicKey = factory.generatePublic(keySpec);

                    // 2. init client private key
                    String privateKey = ViewerApp.getInstance().getSession().getPrivateKey();
                    byte[] privateBytes = Base64.decode(privateKey, Base64.DEFAULT);
                    PKCS8EncodedKeySpec spec = new PKCS8EncodedKeySpec(privateBytes);
                    PrivateKey localPrivateKey = factory.generatePrivate(spec);

                    // 3. Generates the shared secret.
                    KeyAgreement agreement = KeyAgreement.getInstance(factory.getAlgorithm());
                    agreement.init(localPrivateKey);
                    agreement.doPhase(publicKey, true);

                    byte[] sharedSecret = agreement.generateSecret();
                    agreementPubKey = bytesToHexString(sharedSecret);
                    listAgreements.add(agreementPubKey);
                }

            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return listAgreements;
    }

    public static String bytesToHexString(byte[] src) {
        StringBuilder stringBuilder = new StringBuilder("");
        if (src == null || src.length <= 0) {
            return null;
        }
        for (int i = 0; i < src.length; i++) {
            int v = src[i] & 0xFF;
            String hv = Integer.toHexString(v);
            if (hv.length() < 2) {
                stringBuilder.append(0);
            }
            stringBuilder.append(hv);
        }
        return stringBuilder.toString();
    }

}
