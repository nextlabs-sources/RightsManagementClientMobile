package appInstance.remoteRepo.sharepoint.util;

import java.io.UnsupportedEncodingException;

/**
 * Created by wwu on 6/4/2015.
 */
public class EncodeUrl {
    public static String stringByAddingPercentEscapesUsingEncoding(String input) {
        try {
            byte[] bytes = input.getBytes("UTF-8");
            StringBuilder sb = new StringBuilder(bytes.length);
            for (int i = 0; i < bytes.length; ++i) {
                int cp = bytes[i] < 0 ? bytes[i] + 256 : bytes[i];
                if (cp <= 0x20 || cp >= 0x7F || (
                        cp == 0x22 || cp == 0x25 || cp == 0x3C ||
                                cp == 0x3E || cp == 0x20 || cp == 0x5B ||
                                cp == 0x5C || cp == 0x5D || cp == 0x5E ||
                                cp == 0x60 || cp == 0x7b || cp == 0x7c ||
                                cp == 0x7d
                )) {
                    sb.append(String.format("%%%02X", cp));
                } else {
                    sb.append((char) cp);
                }
            }
            return sb.toString();
        } catch (UnsupportedEncodingException e) {

        }
        return input;
    }
}
