package hzcstclient;

import com.hazelcast.client.HazelcastClient;
import com.hazelcast.client.config.ClientConfig;
import com.hazelcast.core.Hazelcast;
import com.hazelcast.core.HazelcastInstance;
import com.hazelcast.core.IMap;
import com.hazelcast.core.IQueue;

public class HzClient {
	 public static void main1(String[] args) {
	        ClientConfig clientConfig = new ClientConfig();
	        HazelcastInstance hazelcastInstance = HazelcastClient.newHazelcastClient(clientConfig);
	        IMap<Object, Object> map = hazelcastInstance.getMap("inventory");
	        System.out.println(map.get("01"));
	        System.out.println(map.get("02"));
	    }
	 public static void main2(String[] args) throws Exception {
		    ClientConfig clientConfig = new ClientConfig();
		    clientConfig.getNetworkConfig().addAddress("10.0.0.96");

		    HazelcastInstance client = HazelcastClient.newHazelcastClient(clientConfig);
		    System.out.println(clientConfig.toString());

		    IQueue<Object> queue = client.getQueue("queue");
		    queue.put("Hello!");
		    System.out.println("Message sent by Hazelcast Client!");

		    HazelcastClient.shutdownAll();
		}
	 public static void main(String[] args) throws InterruptedException {
//	        System.setProperty("hazelcast.logging.type", "log4j");
	        HazelcastInstance hazelcast = Hazelcast.newHazelcastInstance();
	        IMap<String, String> empMap = hazelcast.getMap("employees");
	        empMap.put("02", "Sam");
	        Thread.sleep(10000);
	        HazelcastInstance hazelcast2 = Hazelcast.newHazelcastInstance();
	         IMap<String, String> empMap2 = hazelcast2.getMap("employees");
	        empMap2.put("01", "Joe");
	        Thread.sleep(10000);
	        ClientConfig clientConfig = new ClientConfig();
	        HazelcastInstance hazelcastInstance = HazelcastClient.newHazelcastClient(clientConfig);
	        IMap map = hazelcastInstance.getMap("employees");
	        System.out.println(map.get("01"));
	        System.out.println(map.get("02"));
	    }
		 
}
