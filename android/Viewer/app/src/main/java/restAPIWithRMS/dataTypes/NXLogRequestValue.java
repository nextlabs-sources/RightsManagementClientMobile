package restAPIWithRMS.dataTypes;

import java.util.ArrayList;
import java.util.List;

import restAPIWithRMS.SendLog;

public class NXLogRequestValue {
    public int agentId;
    public List<String> rights;
    public String operation;
    public String userName;  //   username@domain
    public String sid;
    public String hostNme;  //  hostName.domain
    public String nxDocPath;
    public LogType type;
    public List<SendLog.Request.Tag> nxDocPathTags;
    public List<SendLog.Request.Policy> hitPolicies;

    public NXLogRequestValue() {
        agentId = -1;
        rights = new ArrayList<>();
        operation = null;
        userName = null;
        sid = null;
        hostNme = null;
        nxDocPath = null;
        type = null;
        nxDocPathTags = new ArrayList<>();
        hitPolicies = new ArrayList<>();
    }

    public enum LogType {
        Evaluation(0), Operation(1);
        private int value;

        LogType(int _value) {
            this.value = _value;
        }

        @Override
        public String toString() {
            return String.valueOf(this.value);
        }

        public int value() {
            return this.value;
        }
    }
}
