package com.amstudio.distribution.data;

import android.content.Context;
import android.content.SharedPreferences;
import com.amstudio.distribution.domain.ReleaseDraft;
import org.json.JSONArray;
import org.json.JSONObject;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

public final class ReleaseStore {
    private static final String PREFS = "am_studio_distribution";
    private static final String KEY_RELEASES = "release_drafts_v1";
    private final SharedPreferences prefs;

    public ReleaseStore(Context context) {
        prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    public synchronized List<ReleaseDraft> all() {
        List<ReleaseDraft> out = new ArrayList<>();
        try {
            JSONArray array = new JSONArray(prefs.getString(KEY_RELEASES, "[]"));
            for (int i = 0; i < array.length(); i++) {
                JSONObject json = array.optJSONObject(i);
                if (json != null) out.add(ReleaseDraft.fromJson(json));
            }
        } catch (Exception ignored) {}
        out.sort(Comparator.comparingLong(ReleaseDraft::getUpdatedAt).reversed());
        return out;
    }

    public synchronized void save(ReleaseDraft draft) {
        if (draft == null) return;
        List<ReleaseDraft> releases = all();
        boolean replaced = false;
        for (int i = 0; i < releases.size(); i++) {
            if (releases.get(i).getId().equals(draft.getId())) {
                releases.set(i, draft);
                replaced = true;
                break;
            }
        }
        if (!replaced) releases.add(draft);
        JSONArray array = new JSONArray();
        for (ReleaseDraft release : releases) {
            try { array.put(release.toJson()); } catch (Exception ignored) {}
        }
        prefs.edit().putString(KEY_RELEASES, array.toString()).apply();
    }
}
